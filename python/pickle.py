#Pickle example
"""
Does the docstring work here?
"""
import pickle

class Brian:
    """
    This is a simple class to demonstrate the use of
    pickle.
    """
    def __init__(self, name):
        """
        Constructor - set the name attribute.
        """
        self.name = name

class Adkins(Brian):
    """
    A class derived from Brian to demonstrate pickling.
    """
    def __init__(self, name, color):
        Brian.__init__(self, name)
        self.color = color

x = Brian('foo')
print x.name
a = Adkins('bar', 'blue')
print a.name
print a.color

f = r'c:\temp\bjapickle'

pickle.dump(x, open(f, 'w'))

y = pickle.load(open(f))

print y.name


