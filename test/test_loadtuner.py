import unittest
import focustuner
from focustuner import *

class test_CCMT1808(unittest.TestCase):

    def setUp(self):
        self.loadtuner = CCMT1808('10.0.0.1',14800,8655)

    def test_successfulConnection(self):
        self.assertTrue(self.loadtuner.connect())

    def test_unsuccessfulConnection(self):
        self.assertFalse(self.loadtuner.connect())

if __name__ == '__main__':
    unittest.main()
