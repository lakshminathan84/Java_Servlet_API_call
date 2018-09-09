package com.cast.rest.demo;

import javax.ws.rs.core.Response;
import org.jboss.resteasy.client.jaxrs.BasicAuthentication;
import org.jboss.resteasy.client.jaxrs.ResteasyClient;
import org.jboss.resteasy.client.jaxrs.ResteasyClientBuilder;
import org.jboss.resteasy.client.jaxrs.ResteasyWebTarget;

public class CallCastApiService {
	
		private static final String RESTURL = "http://localhost:8090/CAST-RESTAPI/rest/";
	
		public String callCASTRestAPI(String baseURL) {
		String v_URL = RESTURL + baseURL;
		System.out.println("REST API CALLED :: "+v_URL);
		ResteasyClient client = new ResteasyClientBuilder().build();
		ResteasyWebTarget target = client.target(v_URL);
		target.register(new BasicAuthentication("architect", "cast"));
		target.request().accept("\"application/json\"");

		Response response = target.request().get();
		System.out.println("REST API response :: "+response.getStatusInfo().toString());
		String value = response.readEntity(String.class);
		response.close();  

		return value;
	}

}
