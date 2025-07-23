package com.vicgroup.keycloak.facial;

import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

import java.util.Collections;
import java.util.List;

public class FacialMfaAuthenticatorFactory implements AuthenticatorFactory {

    public static final String ID = "central-vet-facial-mfa";
    private String deepUrl;

    @Override public String getId() { return ID; }

    @Override
    public void init(Config.Scope cfg) {
        /* lee de standalone.conf / env */
        deepUrl = "http://localhost:8090/api/auth";

//        deepUrl = cfg.get("deepface-url", "http://localhost:5000/api");

    }

    @Override public void postInit(KeycloakSessionFactory factory) {}

    @Override
    public Authenticator create(KeycloakSession session) {
        return new FacialMfaAuthenticator(deepUrl);
    }
    @Override
    public void close() {
        // No resources to clean up
    }
    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return Collections.emptyList(); // No hay propiedades configurables por el admin
    }
    @Override
    public String getHelpText() {
        return "Autenticación multifactor usando reconocimiento facial";
    }

    /* info UI */
    @Override public String getDisplayType()             { return "Facial MFA"; }
    @Override public String getReferenceCategory()       { return "mfa"; }
    @Override public boolean isConfigurable()            { return false; }
    @Override public boolean isUserSetupAllowed()        { return false; }
    @Override public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return new AuthenticationExecutionModel.Requirement[]{ AuthenticationExecutionModel.Requirement.REQUIRED, AuthenticationExecutionModel.Requirement.DISABLED };
    }

}

