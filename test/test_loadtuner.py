import unittest
import src
from src.main.tuner import *

class test_CCMT1808(unittest.TestCase):

    def setUp(self):
        self.loadtuner = CCMT1808('10.0.0.1',14800,8655)

    def test_sucessfulConnection(self):
        self.assertTrue(self.loadtuner.connect())

    def test_unsucessfulConnection(self):
        self.assertFalse(self.loadtuner.connect())

if __name__ == '__main__':
    unittest.main()
