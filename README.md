# Mask Detection

<br>

Hello guys!

*Welcome to my blog. In this article, I want to share my exploration of a mask detection project developed with Flutter* 
*which can be helpful for KYC processes involving user face verification, such as Liveness Detection and Face Recognition.*

<br>
<br>

![Demo Gif](./mask_demo.jpg)


<br>

If you would like to test it, please download the APK from the following link : 
[Download APK](https://tsfr.io/join/t6xts2?id=11139322)

---

<br>
<br>

## Technologies Used

- **Flutter**: Cross-platform UI framework for building the mobile application.
- **TensorFlow Lite**: Lightweight machine learning model framework for excecute model on device.
- **Mask Detection Model**: Existing ML Model public by https://github.com/chandrikadeb7/Face-Mask-Detection
- **Google MLKit Face Detection**: Official Google ML for detect face from rgb image
- **Camera Plugin**: Flutter plugin (`camera`) for accessing device camera and capturing frames.


<br>
<br>

## Integrating the Model

For this project, I utilized a model available from [this GitHub repository](https://github.com/chandrikadeb7/Face-Mask-Detection). The model is designed for face mask detection and is optimized for Android devices, making it suitable for integration into Kotlin via TensorFlow Lite.


<br>
<br>

## Conclusion
*In this blog, I aimed to share my exploration of Mask Detection, which can be helpful for KYC processes involving user face verification, such as Liveness Detection and Face Recognition.*

<br>

*You can find full implement source code in repo :*

[https://github.com/horlengg/mask_detector](https://github.com/horlengg/mask_detector)

*Thank for reading!.*

<br>
<br>
<br>
<br>