package com.cast.rest.demo;

import org.json.JSONArray;

import org.json.JSONObject;


/**
 * @author LKS
 * Generic REST Client to invoke the CAST AIP REST Interface and extract the TQI value of all the applications
 * hosted onboarded in the platform. 
 *
 */
public class CASTRestClient {


	public static void main( String[] args )
	{
		CallCastApiService callCast = new CallCastApiService();
		String value = callCast.callCASTRestAPI("");
		System.out.println("JSON Base Response :: "+value);

		JSONObject jObj = new JSONObject(value.substring(1, value.length()-1));

		JSONObject tempObj = jObj.getJSONObject("applications");
		Object level = tempObj.get("href");

		String value1 = callCast.callCASTRestAPI(level.toString());
		System.out.println("Application List :: "+value1);


		JSONArray jsonArray = new JSONArray(value1);

		int count = jsonArray.length();

		//Loop through all the applications on boarded in CAST AIP
		for(int i=0 ; i< count; i++){ 
			jObj = jsonArray.getJSONObject(i);
			String applicationURL = (String) jObj.get("href");
			String applicationName = (String) jObj.get("name");

			System.out.println("\n");
			System.out.println("Application name is :: "+applicationName+ " Relative URL is :: " +applicationURL);

			String v1 = callCast.callCASTRestAPI(applicationURL);

			JSONObject v_jObj = new JSONObject(v1);
			JSONObject v_tempObj = v_jObj.getJSONObject("results");
			Object result = v_tempObj.get("href");


			System.out.println("V1 :: "+v1);
			System.out.println("Results URL :: "+ result);
			String resultData = callCast.callCASTRestAPI(result.toString());
			JSONObject v_tqi_result = new JSONObject(resultData.substring(1, resultData.length()-1));

			JSONArray tqi_Obj = (JSONArray) v_tqi_result.get("applicationResults");
			JSONObject tqi_value = tqi_Obj.getJSONObject(0);

			System.out.println(tqi_value.get("result"));
			System.out.println("\n");

		}
	}
}
