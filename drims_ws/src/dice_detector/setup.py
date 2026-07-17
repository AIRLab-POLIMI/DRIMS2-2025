from setuptools import find_packages, setup

package_name = 'dice_detector'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='drims',
    maintainer_email='drims@todo.todo',
    description='The dice detector package',
    license='license',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
             'dice_detector = dice_detector.dice_detector:main',
        ],
    },
)
