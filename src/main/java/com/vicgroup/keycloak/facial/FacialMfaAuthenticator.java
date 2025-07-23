package com.vicgroup.keycloak.facial;

import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
//import org.keycloak.authentication.AuthenticatorFlowError;

import org.keycloak.authentication.AuthenticationFlowError; // ✅ correcto

import org.jboss.logging.Logger;


import org.keycloak.models.UserModel;
import org.keycloak.theme.Theme;

import java.io.IOException;

public class FacialMfaAuthenticator implements Authenticator {
    private static final Logger log = Logger.getLogger(FacialMfaAuthenticator.class);

    static final String ATTR_FLAG = "has_facial_auth";
    private final DeepFaceService deep;

    public FacialMfaAuthenticator(String deepUrl) {
        this.deep = new DeepFaceService(deepUrl);
    }

    /* 1️⃣ paso "browser" */
    @Override
    public void authenticate(AuthenticationFlowContext ctx) {
        UserModel user = ctx.getUser();
        try {
            String themeName = ctx.getSession().theme().getTheme(Theme.Type.LOGIN).getName();
            log.infof("Login theme in use: %s", themeName);
        } catch (IOException e) {
            log.error("Failed to get login theme", e);
        }
        /* Solo si el atributo está a true */
        if (!"true".equals(user.getFirstAttribute(ATTR_FLAG))) {
//            ctx.attempted();                 // saltar MFA
            ctx.success();          // ←  ¡éxito inmediato!

            return;
        }

        /* Mostrar página con la webcam */
        Response challenge = ctx.form()
                .setAttribute("userEmail", user.getEmail())
                .createForm("facial-mfa.ftl");
        ctx.challenge(challenge);
    }

    /* 2️⃣  POST de la página */
    @Override
    public void action(AuthenticationFlowContext ctx) {

        MultivaluedMap<String, String> form = ctx.getHttpRequest().getDecodedFormParameters();
        String imageB64 = form.getFirst("face");          // data:image/...;base64,xxx

        if (imageB64 == null || imageB64.isBlank()) {
            ctx.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
            return;
        }

//        long vetId = Long.parseLong(ctx.getUser().getId()); // tu id local == kcId? usa atributo si no
        String vetId = ctx.getUser().getId();          // UUID
//        boolean ok = deep.verify(vetId, imageB64);


        boolean ok = deep.verify(vetId, imageB64);

        if (ok) ctx.success();
        else    ctx.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
    }

    /* ---------- boilerplate ---------- */
    @Override public boolean requiresUser()     { return true; }

    @Override
    public boolean configuredFor(org.keycloak.models.KeycloakSession session,
                                 org.keycloak.models.RealmModel realm,
                                 org.keycloak.models.UserModel user) {
        return true;
    }
    @Override
    public void setRequiredActions(org.keycloak.models.KeycloakSession session,
                                   org.keycloak.models.RealmModel realm,
                                   org.keycloak.models.UserModel user) {
        // No se necesita lógica en este caso
    }


    //    @Override public boolean configuredFor(org.keycloak.models.KeycloakSession s, UserModel u) { return true; }
//    @Override public void setRequiredActions(org.keycloak.models.KeycloakSession s, UserModel u) {}
    @Override public void close() {}
}
