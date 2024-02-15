from setuptools import find_packages, setup

setup(
    name='loadtuner',
    packages=find_packages(include=['loadtuner']),
    version='0.1.0',
    description='Focus Load Tuner Control Functions in Python',
    author='Scott Shafer',
    install_requires=[],
    setup_requires=['pytest-runner'],
    tests_require=['pytest==4.4.1'],
    test_suite='tests'
)
