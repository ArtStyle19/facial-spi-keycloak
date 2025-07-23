ggggggggggggggggggggggggg<#-- Sin layout.header/footer -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${msg('facialVerifyTitle')}</title>
</head>
<body>

<h2>${msg('facialVerifyTitle')}</h2>
<p>Hola ${userEmail}, acerca tu rostro a la cámara y pulsa “Verificar”.</p>

<form id="kc-facial-form" method="post" action="${url.loginAction}">
    <video id="webcam" autoplay playsinline></video>
    <input type="hidden" name="face" id="face" />
    <button type="button" onclick="captureAndSubmit()">
        ${msg('doVerify')}
    </button>
</form>

<script>
    async function startCam(){
        const v = document.getElementById('webcam');
        try{
            v.srcObject = await navigator.mediaDevices.getUserMedia({video:true});
        }catch(e){ alert('No camera'); }
    }
    function captureAndSubmit(){
        const v = document.getElementById('webcam');
        const c = document.createElement('canvas');
        c.width = v.videoWidth;  c.height = v.videoHeight;
        c.getContext('2d').drawImage(v,0,0);
        document.getElementById('face').value = c.toDataURL('image/jpeg');
        document.getElementById('kc-facial-form').submit();
    }
    startCam();
</script>

</body>
</html>
