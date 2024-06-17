from setuptools import find_packages, setup

with open("README", 'r') as f:
    long_description = f.read()

setup(
    name='focustuner',
    packages=find_packages(include=['focustuner']),
    version='0.1.3',
    description='Focus Load Tuner Control Functions in Python',
    long_description=long_description,
    license="MIT",
    url="https://github.com/RFPAL-Github-Organization/LoadTuner-repo",
    author='Grace Gomez',
    install_requires=[],
    setup_requires=['pytest-runner'],
    tests_require=['pytest==4.4.1'],
    test_suite='tests'
)
s