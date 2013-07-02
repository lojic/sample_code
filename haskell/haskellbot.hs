{-# LANGUAGE GeneralizedNewtypeDeriving #-}

{-
This code started from the "Roll your own IRC bot" article by Don
Stewart on haskell.org:
http://www.haskell.org/haskellwiki/Roll_your_own_IRC_bot

I then received a lot of help from David Joyner.

Copyright (c) 2012 Brian Adkins
MIT License: http://opensource.org/licenses/MIT

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-}

{-
sudo apt-get install ghc
sudo apt-get install cabal-install
sudo cabal update
sudo cabal install regex-compat
sudo cabal install network
-}

{-
TODO
Detect netsplits. This might help:
http://www.emacswiki.org/emacs/ErcNetsplit
-}

import Data.Char
import Data.List
import Network
import System.IO
import System.Exit
import Control.Arrow
import Control.Concurrent
import Control.Monad.Reader
import Control.Monad.State
import Control.Exception -- *** for base-3
-- import Control.OldException -- *** for base-4
import Text.Printf
import Prelude hiding (catch)
import System.Time
import Text.Regex.Posix

{-
  server = "localhost"
  port   = 7000
  chan   = "##testchannel"
  nick   = "haskellbot"
  histFile = "trinomad.html"
-}

server = "irc.freenode.org"
port   = 6667
chan   = "##TriNomad"
nick   = "haskellbot4"
histFile = "/home/deploy/vmls/current/public/trinomad.html"

hist   = 20
pat    = "^:([^!]+)!.*PRIVMSG[^:]+:(.*)$"

-- The 'Net' monad stack, a wrapper over IO, carrying the bot's immutable
-- environment (BotEnv) and its mutable state (BotState).
newtype Net r = Net { unNet :: StateT BotState (ReaderT BotEnv IO) r }
  deriving (Functor, Monad, MonadReader BotEnv, MonadState BotState, MonadIO)

-- Run a function in the 'Net' monad stack. Takes the bot's immutable
-- environment and mutable state as input, returns the result and next
-- state as a pair.
runNet :: BotEnv -> BotState -> Net r -> IO (r, BotState)
runNet e s f = runReaderT (runStateT (unNet f) s) e

-- Bot's immutable environment
data BotEnv = Bot { socket :: Handle, starttime :: ClockTime }

-- Bot's mutable state
type BotState = [String]

-- Set up actions to run on start and end, and run the main loop
main :: IO ()
main = bracket start end loop >>= (const $ return ())
  where
    start         = connect >>= (\ env -> return (env, []))
    end           = hClose . socket . fst
    loop t@(e, s) = catch
                      (runNet e s run >>= (\ (_, s') -> return (e, s')))
                      (const $ return t :: IOException -> IO (BotEnv, BotState))

-- Connect to the server and return the bot environment
connect :: IO BotEnv
connect = notify $ do
    t <- getClockTime
    h <- connectTo server (PortNumber (fromIntegral port))
    hSetBuffering h NoBuffering
    return (Bot h t)
  where
    notify a = bracket_
        (printf "Connecting to %s ... " server >> hFlush stdout)
        (putStrLn "done.")
        a

-- We're in the Net monad now, so we've connected successfully
-- Join a channel, and start processing commands
run :: Net ()
run = do
    write "NICK" nick
    write "USER" (nick++" 0 * :tutorial bot")
    write "JOIN" chan
    asks socket >>= listen

modifyHistory :: String -> BotState -> BotState
modifyHistory s st = if isHistMsg s then take hist (s:st)
                     else st

isHistMsg x = (x =~ "^:.*!.*PRIVMSG.*:[^!]" :: Bool)

-- Process each line from the server
listen :: Handle -> Net ()
listen h = forever $ do
    s <- init `fmap` io (hGetLine h)
    modify (\ st -> modifyHistory s st)
    io (putStrLn s)
    writeToFile s
    if ping s then pong s else eval (user s) (clean s)
  where
    forever a = a >> forever a
    ping x    = "PING :" `isPrefixOf` x
    pong x    = write "PONG" (':' : drop 6 x)

clean     = drop 1 . dropWhile (/= ':') . drop 1
user      = drop 1 . takeWhile (/= '!')

-- Write line to file if history line
writeToFile :: String -> Net ()
writeToFile s = if isHistMsg s
                then io (writeLine ((user s) ++ ": " ++ (formatHistoryLine (clean s))))
                else return ()
  where
    writeLine s = do
      now <- getClockTime
      outh <- openFile histFile AppendMode
      hPutStrLn outh (escapeHistoryLine ((show now) ++ ": " ++ s))
      hClose outh
    formatHistoryLine s
      | "\001ACTION" `isPrefixOf` s = '*' : (init (drop 7 s))
      | otherwise = s

escapeHistoryLine :: String -> String
escapeHistoryLine []       = []
escapeHistoryLine (x:xs) | x == '<' = "&lt;" ++ escapeHistoryLine xs
                         | x == '>' = "&gt;" ++ escapeHistoryLine xs
                         | otherwise = x : escapeHistoryLine xs

-- Dispatch a command
eval :: String -> String -> Net ()
eval  user "!help" = do
  msg user "Help info:"
  msg user "History: http://veterinarymls.com/trinomad.html"
  msg user ("/msg " ++ nick ++ " !history    # Display history")
  msg user ("/msg " ++ nick ++ " !history 1  # Display most recent history line")
  msg user "!uptime  # Display bot uptime"
  return ()

eval  user "!quit289" = write "QUIT" ":Exiting" >> io (exitWith ExitSuccess)
eval  user "!uptime"  = uptime >>= privmsg

eval  user "!history 1" = do
  h <- get
  dumpHistory user (take 1 h) 0
  return ()

eval  user "!history" = do
  h <- get
  msg user "History in reverse chrono in case flood throttling truncates :)"
  dumpHistory user h 100000
  return ()

eval user x | "!id " `isPrefixOf` x = privmsg (drop 4 x)
eval user _                         = return () -- ignore everything else

dumpHistory :: String -> [ String ] -> Int -> Net ()
dumpHistory user [] _ = return ()
dumpHistory user (x:xs) delay = do
    dumpLine user x
    io $ threadDelay delay
    dumpHistory user xs (delay + delta)
  where delta = 100000

dumpLine :: String -> String -> Net ()
dumpLine user line = do
    if length matches == 2 then msg user ((matches !! 0) ++ ": " ++ (matches !! 1))
    else return ()
  where
    (_,_,_,matches) = (line =~ pat :: (String,String,String,[String]))

uptime :: Net String
uptime = do
       now <- io getClockTime
       zero <- asks starttime
       return . pretty $ diffClockTimes now zero

--
-- Pretty print the date in '1d 9h 9m 17s' format
--
pretty :: TimeDiff -> String
pretty td =
  unwords $ map (uncurry (++) . first show) $
  if null diffs then [(0,"s")] else diffs
  where merge (tot,acc) (sec,typ) = let (sec',tot') = divMod tot sec
                                    in (tot',(sec',typ):acc)
        metrics = [(86400,"d"),(3600,"h"),(60,"m"),(1,"s")]
        diffs = filter ((/= 0) . fst) $ reverse $ snd $
                foldl' merge (tdSec td,[]) metrics

-- Send a privmsg to the current chan + server
privmsg :: String -> Net ()
privmsg s = write "PRIVMSG" (chan ++ " :" ++ s)

-- Direct message
msg :: String -> String -> Net ()
msg user s = write "PRIVMSG" (user ++ " :" ++ s)

-- Send a message out to the server we're currently connected to
write :: String -> String -> Net ()
write s t = do
    h <- asks socket
    io $ hPrintf h "%s %s\r\n" s t
    io $ printf    "> %s %s\n" s t

-- Convenience.
io :: IO a -> Net a
io = liftIO
