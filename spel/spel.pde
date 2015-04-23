
//IMPORT LIBRARIES

//unfolding
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.events.*;

//leapmotion
import com.onformative.leap.*;
import com.leapmotion.leap.*;
import com.leapmotion.leap.Gesture.State; 
import com.leapmotion.leap.Gesture.Type;
import com.leapmotion.leap.KeyTapGesture;
import com.leapmotion.leap.ScreenTapGesture;
import com.leapmotion.leap.CircleGesture;   

//geonames
import org.geonames.*;

//andere
import java.net.*;
import codeanticode.glgraphics.*;

DefaultHttpClient httpClient;


//GLOBALE VARIABELEN

//create a reference to a "Map" object
UnfoldingMap myMap;
//locaties
de.fhpotsdam.unfolding.geo.Location belgieLocation = new de.fhpotsdam.unfolding.geo.Location(50.859591f, 4.350117f);

//Geonames user name
String username = "frederic.gryspeerdt";
String countryClick;

LeapMotionP5 leap;

JSONObject json;

//telkens er geklikt wordt, moet een marker opgeslagen worden
ArrayList<MarkerInfo> lstMarkers = new ArrayList();

ScreenPosition centerPos;
Location centerLoc;
Location handLoc;


PVector fingerPos;
PVector handPos;

//HUE
String KEY = "fredericgryspeerdt"; // "secret" key/token
String IP = "172.23.190.22"; // ip bridge

int hue = 0;	//rood = 0 of 65280 / groen = 25500 tot 36210 / blauw = 46920
int brightness = 0;	//van 0 tot 255
int saturation = 0;

//LOGICA
Location searchLoc = new Location(50.835925, 4.350409);	//locatie die gezocht moet worden
SimplePointMarker searchMark = new SimplePointMarker(searchLoc);

Location cursorLoc;	//locatie van de cursor
int distance;	//afstand tussen gezochte locatie en locatie van "cursor"

//GAME
int gameState = 1; //0 = INTRO - 1 = STARTED - 3 = STOPPED

void setup() {
	//Venster aanmaken
	size(800,600);
	smooth();
	frameRate(10);

	//INIT UNFOLDING
	setupMyMap();

	//INIT GEONAMES
	setupGeoNamesWebService();

	//INIT LEAPMOTION
  	setupLeapMotion();

  	//HttpCLient
  	httpClient = new DefaultHttpClient();

	//logger: will setup basic logging to the console
	org.apache.log4j.BasicConfigurator.configure();
}

void draw() {

	switch (gameState) {
		case 0 : //INTRO
			background(0);
		break;	

		case 1 : //STARTED
				myMap.draw();
	
				//get the Location of the map at the current mouse position, and show its latitude and longitude as black text.
				//Location location = myMap.getLocation(mouseX, mouseY);
				//text(location.getLat() + ", " + location.getLon(), mouseX, mouseY);
				
				//weergeven van alle markers (plaatsen waar geklikt is)
				addMarkers(lstMarkers);

				try {
			      //text(mouseX + ", " + mouseY,mouseX,mouseY);
			      fingerPos = leap.getTip(leap.getFinger(0));    
			    } catch (Exception e) {
			      println("> fingerposition: "+e);
			    }
			    
			    try {
			       for (Hand hand : leap.getHandList()) {
			        handPos = leap.getPosition(hand);
			        ellipse(handPos.x, handPos.y, 20, 20);
			        fill(255);
			        ellipse(handPos.x, handPos.y, 20, 20);

			        checkPanning(handPos);
			        handLoc = new Location(handPos.x, handPos.y);
			      }
			    } catch (Exception e) {
			      println("> handPos: "+e);
			    }


			    //aanvulling
			    try {
			    	cursorLoc = myMap.getLocation(mouseX, mouseY);
			    	distance = (int)searchLoc.getDistance(cursorLoc);
			    	println(">> DISTANCE: " + distance);
			    	//distanceToColorConverter();

			    	checkDistance();
			    	//hueTest();

			    } catch (Exception e) {
			    	println(">> DISTANCE: " + e);
			    }
					break;	
				}
	

}

void keyPressed() {
  if (key == 's') {
    gameState = 1;
	}
 }

public void hueTest(){
	try {
    String data = "{\"on\":true, \"hue\":"+hue+", \"bri\":"+brightness+", \"sat\":"+saturation+", \"transitiontime\":5}";

    StringEntity se = new StringEntity(data);
    HttpPut httpPut = new HttpPut("http://"+IP+"/api/"+KEY+"/lights/3/state");

    httpPut.setEntity(se);

    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    if (entity != null) entity.consumeContent();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}

public void checkDistance(){
	//max hue = 65.280
	//max brightness = 255
	//max saturation = 255
	//max distance = +-20.000

	hue = (int)map(distance, 0, 20000, 0, 46920); // hoe dichter bij gezochte locatie, hoe rooder 
	//println("hue: "+hue);
	brightness = (int)map(distance, 0, 20000, 170, 0); //hoe dicht bij gezochte locatie, hoe meer helder
	//println("brightness: "+brightness);
	saturation = (int)map(distance, 0, 20000, 255, 0); // hoe dichter bij gezochte locatie, hoe meer saturation
	//println("saturation;: "+saturation);
}





public void checkPanning(PVector handPosition){

    Location panLocation = myMap.getLocation(handPosition.x,handPosition.y);
    // map.panTo(handPosition.x, handPosition.y);
    myMap.panTo(panLocation);
}

void addMarkers(ArrayList<MarkerInfo> lst){
	try {
		//alle markers overlopen in ArrayList
		for (MarkerInfo markInfo : lst) {

			//MarkerInfo heeft 2 fields: marker (SimplePointMarker, de default marker) en info (String, bevat naam land)
			Location clickLocation = markInfo.marker.getLocation();
			ScreenPosition clickPos = markInfo.marker.getScreenPosition(myMap);
			float txtWidth = textWidth(markInfo.info);
	  		

			//we maken een custom marker 'ClickLocationMarker' (zelfgemaakte klasse)
			ClickLocationMarker clickMarker = new ClickLocationMarker(clickLocation, markInfo.info, txtWidth);
			//plaatsen marker op de map
			myMap.addMarkers(clickMarker);
		
		}
	} catch (Exception e) {
		println("> addMarker: "+e);
	}
	
}
//Willekeurig nieuw land kiezen
void RandomCountry()
{

}

//Afstand berekenen tussen aangeduide plek en random land
void CalculateDistance()
{

}

//TODO: 

//Tekstvakje dat naam van een land weergeeft

//Google maps weergeven

//Afstand berekenen van random land en philips hueu daarmee aansturen

//Uitzoeken hoe 2 spelers te kunnen connecteren.
// https://processing.org/reference/libraries/net/Server.html
// https://processing.org/reference/libraries/net/Client.html


public void setupMyMap(){
	//initialize a new map object and add default event functioning
	//for basis interaction
	myMap = new UnfoldingMap(this,new Microsoft.AerialProvider());	//use another then default map style


	//UnfoldingMap(processing.core.PApplet p, float x, float y, float width, float height)
  	//Creates a new map with specific position and dimension. 
 	//myMap = new UnfoldingMap(this, 0f,0f,width,height,new Microsoft.AerialProvider());
 	//println((int)map.getWidth()+"," +(int)map.getHeight());
	MapUtils.createDefaultEventDispatcher(this, myMap); //basisinteractie toevoegen: map reageert op muis en toetsen
	
  	centerPos = new ScreenPosition(width/2,height/2);
  	centerLoc = myMap.getLocation(centerPos);
  	myMap.zoomAndPanTo(centerLoc,2);
  	//myMap.setPanningRestriction(centerLoc, 10000);
  	//myMap.setScaleRange(1f, 18f);

  	myMap.setZoomRange(2,18);		//2 = max uitzoomlevel; 18 = max. inzoomlevel
  									//range: 0 is max. uitgezoomd, 18 (of meer indien mogelijk) is max. uitgezoomd


  	myMap.addMarker(searchMark);								
}

public void setupGeoNamesWebService(){
	//setup webservice geonames
	WebService.setUserName("frederic.gryspeerdt");
}

public void setupLeapMotion(){
  leap = new LeapMotionP5(this);
  leap.enableGesture(Type.TYPE_SCREEN_TAP);
  leap.enableGesture(Type.TYPE_CIRCLE);
  leap.enableGesture(Type.TYPE_KEY_TAP);
}

void mouseClicked() {
	//locatie ophalen adhv x en y van muis
 	Location clickLocation = myMap.getLocation(mouseX, mouseY);
 	//marker aanmaken (die later op de map zal worden getoond)
	SimplePointMarker clickMarker = new SimplePointMarker(clickLocation);
 	//ScreenPosition clickPos = clickMarker.getScreenPosition(myMap);
 	zoekNaamLocatie(clickLocation);
 	MarkerInfo markInfo = new MarkerInfo(clickMarker, countryClick);
 	lstMarkers.add(markInfo);
 	//println("lstMarkers: "+lstMarkers);
}


public void zoekNaamLocatie(Location clickLocation) {
	//obv de clickLocatie (gebruiker heeft ergens op de kaart geklikt), de naam van het land (en andere info)
	//waarop geklikt werd, ophalen
	//we gebruiken hiervoor de webservice van geonames: obv latitude en longitude kan deze dit achterhalen

	//ophalen latitude en longitude van clickLocation
	float lat = clickLocation.getLat();
	float lon = clickLocation.getLon();

	//service aanspreken op volgende link: http://api.geonames.org/findNearbyPlaceNameJSON?lat=[X].3&lng=[X]&username=[X]
	try {
		//try - catch is verplicht als je met URI werkt
		URI uri = new URIBuilder()
        .setScheme("http")
        .setHost("api.geonames.org")
        .setPath("/findNearbyJSON")
        .setParameter("lat", ""+lat)
        .setParameter("lng", ""+lon)
        .setParameter("username", username)
        .build();

		//println("> URI = "" + uri);

		//webservice heeft json terug
		json = loadJSONObject(""+uri);
  		//println("> json: "+json);

  		//Get the element that holds the information
  		JSONArray values = json.getJSONArray("geonames");
  		//println("values: "+values.size());

  		//array overlopen
  		for (int i = 0; i < values.size(); i++) {
    
    		JSONObject geoname = values.getJSONObject(i); 

    		//land waarop geklikt werd ophalen
    		countryClick = geoname.getString("countryName");
  			//println("> countryClick: "+countryClick);
  		}
	} catch (Exception e) {
		println("> zoekNaamLocatie: "+ e);
		countryClick = "Onbekend";
	}
}


public void screenTapGestureRecognized(ScreenTapGesture gesture) {
  if (gesture.state() == State.STATE_STOP) {
	println("> SCREENTAP");

  	/*
    System.out.println("//////////////////////////////////////");
    System.out.println("Gesture type: " + gesture.type());
    System.out.println("ID: " + gesture.id());
    System.out.println("Position: " + leap.vectorToPVector(gesture.position()));
    System.out.println("Direction: " + gesture.direction());
    System.out.println("Duration: " + gesture.durationSeconds() + "s");
    System.out.println("//////////////////////////////////////");
	*/
 

    Location tapLocation = myMap.getLocation(handPos.x, handPos.y);
    SimplePointMarker tapMarker = new SimplePointMarker(tapLocation);
    zoekNaamLocatie(tapLocation);
    MarkerInfo markInfo = new MarkerInfo(tapMarker, countryClick);
    //ScreenPosition tapPos = tapMarker.getScreenPosition(myMap);
      
    lstMarkers.add(markInfo);
    //println("lstMarkers: "+lstMarkers); 

    /*
    PVector position = leap.vectorToPVector(gesture.position());
    float xposFinger = position.x;
    float yposFinger = position.y;

    println("xposFinger: "+xposFinger);
    println("yposFinger: "+yposFinger);

    float xposMouse = mouseX;
    float yposMouse = mouseY;

    println("xposMouse: "+xposMouse);
    println("yposMouse: "+yposMouse);
    */

  } 
  else if (gesture.state() == State.STATE_START) {

  } 
  else if (gesture.state() == State.STATE_UPDATE) {
   
  }
}

public void circleGestureRecognized(CircleGesture gesture, String clockwiseness) {
  if (gesture.state() == State.STATE_STOP) {
  	 /*
    System.out.println("//////////////////////////////////////");
    System.out.println("Gesture type: " + gesture.type().toString());
    System.out.println("ID: " + gesture.id());
    System.out.println("Radius: " + gesture.radius());
    System.out.println("Normal: " + gesture.normal());
    System.out.println("Clockwiseness: " + clockwiseness);
    System.out.println("Turns: " + gesture.progress());
    System.out.println("Center: " + leap.vectorToPVector(gesture.center()));
    System.out.println("Duration: " + gesture.durationSeconds() + "s");
    System.out.println("//////////////////////////////////////");
    */

    PVector center = leap.vectorToPVector(gesture.center());
    ScreenPosition handPos = new ScreenPosition(center.x, center.y);   //-----> BELANGRIJK: gebruik screenpostion en zet daarna om in screenLocation!
                                                                      // anders niet correct!

    //Location circleLoc = new Location(fingerPos.x, fingerPos.y);
    //Location circleLoc = new Location(center.x, center.y);
    Location circleLoc = myMap.getLocation(handPos);


    int zoomLvl = myMap.getZoomLevel();
    if (clockwiseness == "clockwise") {

      println("> CIRCLE: clockwise");
      myMap.zoomLevelIn();
      //myMap.zoomAndPanTo(circleLoc,zoomLvl + 1);
      myMap.panTo(circleLoc);
      
                
    } else {

      println("> CIRCLE: counterclockwise");
      myMap.zoomLevelOut();
      //map.zoomAndPanTo(circleLoc, zoomLvl - 1);
      //map.panTo(center.x,center.y);
      myMap.panTo(circleLoc);
    }

   

  } 
  else if (gesture.state() == State.STATE_START) {
  } 
  else if (gesture.state() == State.STATE_UPDATE) {
  }
}



public void stop() {
  leap.stop();
  httpClient.getConnectionManager().shutdown();
  super.stop();
}	