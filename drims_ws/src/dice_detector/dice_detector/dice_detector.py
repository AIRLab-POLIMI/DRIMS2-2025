import rclpy
from rclpy.node import Node

from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2

from drims2_msgs.srv import DiceIdentification
from geometry_msgs.msg import PoseStamped


class DiceDetector(Node):
    def __init__(self):
        super().__init__('dice_detector')

        # Bridge OpenCV <-> ROS
        self.bridge = CvBridge()

        # Subscriber
        self.subscription = self.create_subscription(
            Image,
            '/color/video/image',
            self.listener_callback,
            10)

        # Publisher
        self.publisher = self.create_publisher(Image, '/dice_detector/circle', 10)

        # Service
        self.srv = self.create_service(DiceIdentification, 'dice_identification', self.handle_service)

        self.get_logger().info("Dice Detector node started")

    def listener_callback(self, msg):
        # Convert ROS image -> OpenCV
        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')

        # Now that you have an opencv object you can work on it. Here we simply draw a circle
        h, w, _ = frame.shape
        center = (w // 2, h // 2)
        cv2.circle(frame, center, 50, (0, 0, 255), 3)

        # Publish the processed image for debug purposes
        img_msg = self.bridge.cv2_to_imgmsg(frame, encoding='bgr8')
        img_msg.header = msg.header
        self.publisher.publish(img_msg)

    def handle_service(self, request, response):
        # Here you put your detection values
        pose = PoseStamped()
        pose.header.stamp = self.get_clock().now().to_msg()
        pose.header.frame_id = "checkerboard"  

        pose.pose.position.x = 1.0
        pose.pose.position.y = 2.0
        pose.pose.position.z = 3.0

        pose.pose.orientation.x = 0.0
        pose.pose.orientation.y = 0.0
        pose.pose.orientation.z = 0.0
        pose.pose.orientation.w = 1.0

        response.face_number = 7
        response.pose = pose
        response.success = True

        self.get_logger().info("Service called -> returning static dice info")
        return response


def main(args=None):
    rclpy.init(args=args)
    node = DiceDetector()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
