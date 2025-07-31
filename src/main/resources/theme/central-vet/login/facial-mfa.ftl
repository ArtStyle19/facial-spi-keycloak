<#import "template.ftl" as layout>
<@layout.registrationLayout
bodyClass=""
displayInfo=false
displayMessage=true
displayRequiredFields=false; section>

    <#if section == "header">
        ${msg('facialVerifyTitle')}

    <#elseif section == "form">
        <h2 class="kc-title">${msg('facialVerifyTitle')}</h2>
        <p>Hola ${userEmail}, acerca tu rostro a la cámara y pulsa “Verificar”.</p>

        <form id="kc-facial-form" method="post" action="${url.loginAction}">

            <div id="feedback-banner" style="
    width: 100%;
    min-height: 100px;
    padding: 12px 16px;
    box-sizing: border-box;
    border-radius: 6px;
    font-weight: 500;
    font-size: 0.95rem;
    text-align: center;
    transition: background-color 0.2s ease, color 0.2s ease, border 0.2s ease;
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid #ffeeba;
    background-color: #ffffff;
    color: #856404;
    position: relative;
    overflow: hidden;
">
  <span id="feedback-text" style="
      display: inline-block;
      opacity: 1;
      transition: opacity 0.2s ease;
  ">
    <!-- JS actualiza esto -->
  </span>
            </div>

            <div id="video-container" style="min-height: 300px; min-width: 300px; position: relative; display: inline-block;">
<#--                <video id="webcam" autoplay playsinline muted style="display: block; border: 1px solid #ccc;"></video>-->
                <video id="webcam" autoplay playsinline muted style="display: block;"></video>
                <canvas id="overlay" style="position: absolute; top: 0; left: 0; pointer-events: none;"></canvas>
            </div>
            <input type="hidden" name="face" id="face" />
            <button id="verify-btn" type="button"
                    class="btn btn-primary btn-block"
                    onclick="captureAndSubmit()"
                    disabled>
                ${msg('Verificar')}
            </button>

<#--            <div id="feedback" style="margin-top: 1em; color: #cc0000; font-weight: 500; min-height: 1.2em;"></div>-->

        </form>

        <!-- MediaPipe Scripts -->
        <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils/camera_utils.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/@mediapipe/drawing_utils/drawing_utils.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/face_mesh.js"></script>

        <script>
            const video = document.getElementById('webcam');
            const canvas = document.getElementById('overlay');
            const ctx = canvas.getContext('2d');
            const verifyBtn = document.getElementById('verify-btn');

            let validationTimer = null;
            let faceHeldValid = false;





            function captureAndSubmit() {
                const c = document.createElement('canvas');
                c.width = video.videoWidth;
                c.height = video.videoHeight;
                c.getContext('2d').drawImage(video, 0, 0);
                document.getElementById('face').value = c.toDataURL('image/jpeg');
                document.getElementById('kc-facial-form').submit();
            }


            function validateFace(landmarks, canvasWidth, canvasHeight) {
                const leftEyeIdx = 33;
                const rightEyeIdx = 263;
                const noseTipIdx = 1;
                const chinIdx = 152;

                const leftEye = landmarks[leftEyeIdx];
                const rightEye = landmarks[rightEyeIdx];
                const noseTip = landmarks[noseTipIdx];
                const chin = landmarks[chinIdx];

                const feedback = [];

                const banner = document.getElementById('feedback-banner');
                const bannerText = document.getElementById('feedback-text');

                let message = "";
                let status = "error";

                // 1. Tamaño / distancia
                const eyeDist = Math.abs(rightEye.x - leftEye.x);
                const midEyeY = (leftEye.y + rightEye.y) / 2;
                const faceHeight = Math.abs(chin.y - midEyeY);
                const isProperSize = eyeDist > 0.08 && eyeDist < 0.3 && faceHeight > 0.1;
                if (!isProperSize) feedback.push("Acercate o alejate ligeramente de la cámara.");

                // 2. Centrado horizontal
                const faceCenterX = noseTip.x;
                const isCentered = faceCenterX > 0.25 && faceCenterX < 0.75;
                if (!isCentered) feedback.push("Alineá tu rostro al centro del recuadro.");

                // 3. Perfil (cara de lado)
                const eyeZDiff = Math.abs(leftEye.z - rightEye.z);
                const isNotProfile = eyeZDiff < 0.035;
                if (!isNotProfile) feedback.push("Mirá directamente al frente.");

                // 4. Nariz entre ojos
                const noseBetweenEyes = noseTip.x > leftEye.x && noseTip.x < rightEye.x;
                if (!noseBetweenEyes) feedback.push("Enderezá tu rostro para que quede de frente.");

                // 5. Inclinación vertical (mirar arriba o abajo)
                const eyeToNose = Math.abs(noseTip.y - midEyeY);
                const noseToChin = Math.abs(chin.y - noseTip.y);
                const verticalRatio = eyeToNose / noseToChin;
                const isNotTilted = verticalRatio > 0.25 && verticalRatio < 0.75;
                if (!isNotTilted) feedback.push("Evitá inclinar la cabeza hacia arriba o abajo.");

                // Mostrar feedback
                // const banner = document.getElementById('feedback-banner');

                <#noparse>

                if (feedback.length > 0) {
                    message = `🔎 ${feedback.at(0)}`;
                    banner.style.backgroundColor = "#fff3cd";
                    banner.style.color = "#856404";
                    banner.style.border = "1px solid #ffeeba";
                } else {
                    message = "✅ ¡Todo listo! Tu rostro está correctamente alineado.";
                    banner.style.backgroundColor = "#d4edda";
                    banner.style.color = "#155724";
                    banner.style.border = "1px solid #c3e6cb";
                }
                </#noparse>

// Mostrar feedback visual
                if (bannerText.textContent !== message) {
                    bannerText.style.opacity = 0;

                    setTimeout(() => {
                        bannerText.textContent = message;
                        bannerText.style.opacity = 1;
                    }, 200);
                }

// ✅ RETORNAR SI ES VÁLIDA O NO
                return feedback.length === 0;
            }


            <#noparse>
            const faceMesh = new FaceMesh({
                locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/${file}`
            });
            </#noparse>

            faceMesh.setOptions({
                maxNumFaces: 1,
                refineLandmarks: true,
                minDetectionConfidence: 0.8,
                minTrackingConfidence: 0.8
            });

            faceMesh.onResults(results => {
                ctx.clearRect(0, 0, canvas.width, canvas.height);

                if (results.multiFaceLandmarks && results.multiFaceLandmarks.length > 0) {
                    let faceValid = false;
                    for (const landmarks of results.multiFaceLandmarks) {
                        window.drawConnectors(ctx, landmarks, window.FACEMESH_TESSELATION, { color: '#A9C3B8', lineWidth: 0.4 });

                        window.drawLandmarks(ctx, landmarks, {
                            color: '#1BBCB6',
                            radius: 0.7
                        });
                        // window.drawConnectors(ctx, landmarks, window.FACEMESH_RIGHT_EYE, { color: '#000000', lineWidth: 0.4 });
                        // window.drawConnectors(ctx, landmarks, window.FACEMESH_LEFT_EYE, { color: '#000000', lineWidth: 0.4 });
                        // window.drawConnectors(ctx, landmarks, window.FACEMESH_LIPS, { color: '#000000', lineWidth: 0.4 });

                        const isFaceGood = validateFace(landmarks, canvas.width, canvas.height);
                        if (isFaceGood) {
                            faceValid = true; // al menos una cara bien detectada
                        }
                    }

                    // const isFaceGood = validateFace(landmarks, canvas.width, canvas.height);
                    // verifyBtn.disabled = false;
                    // verifyBtn.disabled = !faceValid;
                    if (faceValid) {
                        if (!faceHeldValid) {
                            if (!validationTimer) {
                                validationTimer = setTimeout(() => {
                                    faceHeldValid = true;
                                    verifyBtn.disabled = false;
                                    verifyBtn.style.opacity = "1";
                                    verifyBtn.style.filter = "none";
                                }, 1000); // 2 segundos seguidos válidos
                            }
                        }
                    } else {
                        // Cancelar temporizador si el rostro deja de ser válido
                        clearTimeout(validationTimer);
                        validationTimer = null;
                        faceHeldValid = false;

                        verifyBtn.disabled = true;
                        verifyBtn.style.opacity = "0.6";
                        verifyBtn.style.filter = "grayscale(60%)";
                    }



                } else {
                    verifyBtn.disabled = true;
                }
            });

            async function startDetection(videoWidth, videoHeight) {
                const camera = new Camera(video, {
                    onFrame: async () => {
                        await faceMesh.send({ image: video });
                    },
                    width: videoWidth,
                    height: videoHeight
                });
                await camera.start();
            }

            async function startCam() {
                try {
                    const stream = await navigator.mediaDevices.getUserMedia({ video: true });
                    video.srcObject = stream;

                    video.onloadedmetadata = () => {
                        const width = video.videoWidth;
                        const height = video.videoHeight;

                        // Ajusta el tamaño real del canvas al del video
                        canvas.width = width;
                        canvas.height = height;

                        // Ajusta también el tamaño visual del canvas para que calce encima
                        canvas.style.width = video.clientWidth + "px";
                        canvas.style.height = video.clientHeight + "px";

                        startDetection(width, height);
                    };
                } catch (err) {
                    alert("Error al acceder a la cámara: " + err.message);
                }
            }

            startCam();
        </script>
    </#if>
</@layout.registrationLayout>
