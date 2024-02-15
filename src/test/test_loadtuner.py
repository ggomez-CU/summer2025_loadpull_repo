import unittest
import src
from src.loadtuner import loadtuner
from src.loadtuner.loadtuner import *

import

class CCMT1808_test(unittest.TestCase):

    def setUp(self):
        self.loadtuner = CCMT1808('10.0.0.1',14800,8655)

    def test_sucessfulConnection(self):
        self.assertTrue(self.loadtuner.connect())
