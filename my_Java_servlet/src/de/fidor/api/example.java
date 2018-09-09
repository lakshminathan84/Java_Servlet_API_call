package de.fidor.api;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.PrintWriter;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.fluent.Request;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.methods.RequestBuilder;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;



import com.mashape.unirest.http.Unirest;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;

import org.json.JSONException;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import java.io.FileReader;


/**
 * Servlet implementation class example
 */
@WebServlet("/example")
public class example extends HttpServlet {
	private static final long serialVersionUID = 1L;
	//The below details are part of the Testapp Application register by me. The client details are taken from there. 
	//The application is added as a registered app for a sandbox user 
	private final String app_url = "http://localhost:8090/my_Java_servlet/example";
	private final String client_id = "7e7240708f963473";
	private final String client_secret = "8f28f27152f29badd94a31867d35850f";
	private final String fidor_oauth_url = "https://apm.sandbox.fidor.com/oauth";
	private final String fidor_api_url = "https://api.sandbox.fidor.com";
	private final String mock_user_url = "https://nznr8vnfxfaiq3ktw-mock.stoplight-proxy.io/users/current";
	private final String mock_account_url ="https://nznr8vnfxfaiq3ktw-mock.stoplight-proxy.io/accounts";
	private HttpClient httpClient;
	private JSONParser parser;
    /**
     * @see HttpServlet#HttpServlet()
     */
    public example() {
        super();
        httpClient = HttpClients.createDefault();
        parser = new JSONParser();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		//The code comes null, so tried calling the getCodeURL() where response(token) is not coming from httpclient.execute
		//String code = getCodeUrl();
		String code = request.getParameter("code");
		if(code == null) {
			//response.sendRedirect(getCodeUrl());
			
			HttpGet request1 = new HttpGet(mock_user_url);
			HttpResponse userResponse = httpClient.execute(request1);
			//httpclient.execute for a mock url works fine
			String body = EntityUtils.toString(userResponse.getEntity());
		
			org.json.simple.JSONObject user = null;
			
			try {
				user = (org.json.simple.JSONObject)parser.parse(body);
			} catch (ParseException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
								
			response.setContentType("text/html");
			PrintWriter writer = response.getWriter();
			writer.append(
					"<h2>Hello here "+ user.get("email") + "</h2>"
					+ "<p> The below is the details of the current user</p>"
					+ "<blockquote>" + body + "</blockquote>"
					+ "<p>The account details are at <br> <a href='" + getAccountUrl() +"'>" + getAccountUrl() +"</a></p>");
		
			HttpGet request2 = new HttpGet(mock_account_url);
			HttpResponse userResponse2 = httpClient.execute(request2);
			//httpclient.execute for a mock url works fine
			String body2 = EntityUtils.toString(userResponse2.getEntity());
		
			org.json.simple.JSONObject account = null;
			
			try {
				account = (org.json.simple.JSONObject)parser.parse(body2);
			} catch (ParseException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
			response.setContentType("text/html");
			PrintWriter writer3 = response.getWriter();
			writer3.append(
					"<h2>Hello here for account details</h2>"
					+ "<blockquote> </blockquote>"
					+ "<blockquote>" + account.get("data") + "</blockquote>");
		            
			}
		
	
					
				
		 else {
			try {
					
				
				String token = getToken(code);
				if(token != null) {
					HttpResponse userResponse = httpClient.execute(RequestBuilder.get().setUri(getUserUri(token)).build());
					String body = EntityUtils.toString(userResponse.getEntity());
					
					JSONObject user = (JSONObject)parser.parse(body);

					response.setContentType("text/html");
					PrintWriter writer = response.getWriter();
					writer.append(
							"<h2>Hello " + user.get("email") + "</h2>"
							+ "<i>May i present the access token response:</i>"
							+ "<blockquote>" + body + "</blockquote>"
							+ "<p>Now use the access token in <br> <a href='" + getAccountUrl(token) +"'>" + getAccountUrl(token) +"</a></p>");
				}
			} catch (URISyntaxException e) {
				e.printStackTrace();
			} catch (ParseException e) {
				e.printStackTrace();
			}

		} 
	}
	
	private URI getUserUri(String token) throws URISyntaxException {
		return new URI(fidor_api_url + "/users/current?access_token=" + token);
	}

	private String getToken(String code) throws URISyntaxException, ClientProtocolException, IOException, ParseException {
		HttpUriRequest req = (HttpUriRequest) RequestBuilder.post()
				.setUri(getTokenUri())
				.addParameter("client_id", client_id)
				.addParameter("redirect_uri", app_url)
				.addParameter("code", code)
				.addParameter("client_secret", client_secret)
				.addParameter("grant_type", "authorization_code")
				.build();

		HttpResponse resp = httpClient.execute(req);
		String body = EntityUtils.toString(resp.getEntity());
		Object jsonResponse = parser.parse(body);
		if(jsonResponse instanceof JSONObject) {
			JSONObject responseObject = (JSONObject)jsonResponse;
			return responseObject.get("access_token").toString();
		} else {
			return null;
		}
	}

	private URI getTokenUri() throws URISyntaxException {
		return new URI(fidor_oauth_url + "/token");
	}

	private String getCodeUrl() {
		return fidor_oauth_url + "/authorize?client_id=" + client_id + "&redirect_uri=" + app_url +"&state=1234&response_type=code";
	}

	private String getAccountUrl(String token) {
		return fidor_api_url + "/accounts?access_token=" + token;
	}
	private String getAccountUrl() {
		return "https://nznr8vnfxfaiq3ktw-mock.stoplight-proxy.io/accounts";
	}
}
