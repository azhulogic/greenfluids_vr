//
//Purpose: Contains the mechanics of the right controller
//
//======================================================

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using System;

public class Right_Controller : MonoBehaviour
{

    public Valve.VR.EVRButtonId trigger = Valve.VR.EVRButtonId.k_EButton_SteamVR_Trigger; 
    [HideInInspector]
    public bool triggerButtonDown = false;

    private Valve.VR.EVRButtonId grip = Valve.VR.EVRButtonId.k_EButton_Grip; 
    [HideInInspector]
    public bool gripButtonUp = false;
    [HideInInspector]
    public bool gripButtonDown = false;

    private Valve.VR.EVRButtonId menu = Valve.VR.EVRButtonId.k_EButton_ApplicationMenu;
    [HideInInspector]
    public bool menuButtonDown = false;

    [HideInInspector]
    public float DeltaStep = 0.3f;

    public float fadeOutTime = 2f;

    //We will use these variables to control the scale of the isosurface
    private Vector3 oldControllerPositionRight;
    private Vector3 oldControllerPositionLeft;
    private GameObject controllerRight;
    private GameObject controllerLeft;

    //Gaining access to the controller location and buttons
    public SteamVR_Controller.Device controller { get { return SteamVR_Controller.Input((int)trackedObj.index); } } 
    private SteamVR_TrackedObject trackedObj;

    //FigInx keeps track of where in the FlowFigure array we are
    [HideInInspector]
    public int FigInx; 

    private int counter_for_menuButton = 1;

    private int counter_for_text = 0;

    // Called Only Once for "Set-Up"
    void Start()
    {
        FigInx = 0;

        trackedObj = GetComponent<SteamVR_TrackedObject>();

        //Used for tracking the controller position so that we can scale the object properly when the trigger is held down
        controllerLeft = GameObject.Find("Controller (left)");
        controllerRight = GameObject.Find("Controller (right)");
        oldControllerPositionRight = controllerRight.transform.localPosition;
        oldControllerPositionLeft = controllerLeft.transform.localPosition;

        if (controllerRight != null)
        {
            Debug.Log("Controller found");
        }
    }
    float counter = 0; //Used for TriggerTimer coroutine


    // Update is called once per frame
    void Update()
    {
        // Making sure that the controller is on and the cameras can see it
        if (controller == null)
        {
            Debug.Log("Right Controller Not Yet Initialized!");
            return;
        }


        triggerButtonDown = controller.GetPressDown(trigger); 


        // Update the controller position so that we can properly scale the object
        Vector3 newControllerPositionRight = controllerRight.transform.localPosition;
        Vector3 newControllerPositionLeft = controllerLeft.transform.localPosition;

        float oldControllerDifference = Vector3.Distance(oldControllerPositionRight, oldControllerPositionLeft);
        float newControllerDifference = Vector3.Distance(newControllerPositionRight, newControllerPositionLeft);

        float controllerDifference = (newControllerDifference - oldControllerDifference) * 300f; 

        //Changing the scale of the all isosurfaces based on how the user moves the right controller in relation to the left controller
        if (controller.GetPress(trigger) && FindObjectOfType<Left_Controller>().controller.GetPress(FindObjectOfType<Left_Controller>().trigger))
        {
            foreach (GameObject figure in FindObjectOfType<GameBuild>().FlowFigures)
            {
                figure.transform.localScale = new Vector3(figure.transform.localScale.x + controllerDifference, figure.transform.localScale.y + controllerDifference, figure.transform.localScale.z + controllerDifference);
            }
        }

        // Now we need to update the controller position so that the position updates every frame
        oldControllerPositionRight = controllerRight.transform.localPosition;
        oldControllerPositionLeft = controllerLeft.transform.localPosition; 


        menuButtonDown = controller.GetPressDown(menu);


        if (menuButtonDown && counter_for_menuButton == 1)
        {
            counter_for_menuButton = 2;
        }
        else if (menuButtonDown && counter_for_menuButton == 2)
        {
            counter_for_menuButton = 1;
        }
        else if (controller.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad) || FindObjectOfType<Left_Controller>().controller.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad))
        {
            counter_for_menuButton = 1;
        }

        //Deactivate or activate the isosurface by pressing the menu button
        for (int i = 0; i < FindObjectOfType<GameBuild>().numTimeSteps * FindObjectOfType<GameBuild>().numQuants; i++)
        {
            if (i != FigInx)
            {
                FindObjectOfType<GameBuild>().FlowFigures[i].SetActive(false);
            }
            else
            {
                if (menuButtonDown && counter_for_menuButton == 2)
                {
                    FindObjectOfType<GameBuild>().FlowFigures[i].SetActive(false); 
                }
                else if (menuButtonDown && counter_for_menuButton == 1)
                {
                    FindObjectOfType<GameBuild>().FlowFigures[i].SetActive(true);
                }
                else if (counter_for_menuButton == 1)
                {
                    FindObjectOfType<GameBuild>().FlowFigures[i].SetActive(true);
                }
            }

        }


        //Move through time steps and quantities with the right touchpad
        if (controller.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad))
        {
            Vector2 touchpoints = controller.GetAxis(Valve.VR.EVRButtonId.k_EButton_Axis0);
            counter = 0;
            if (touchpoints.y >= 0.0f && (FigInx + 1) % FindObjectOfType<GameBuild>().numTimeSteps == 0) //Pressing the upper half plane changes the time step
            {
                FigInx = FigInx - (FindObjectOfType<GameBuild>().numTimeSteps - 1); //Switch to the first time step in the quantity if the next time step is the last in the quantity
            }
            else if (touchpoints.y >= 0.0f && (FigInx + 1) % FindObjectOfType<GameBuild>().numTimeSteps != 0) 
            {
                FigInx = FigInx + 1; //Move forward one time step if the next one is not the last time step in the quantity
            }
            else if (touchpoints.y < 0 && FigInx >= FindObjectOfType<GameBuild>().numTimeSteps * (FindObjectOfType<GameBuild>().numQuants - 1))  //Pressing the lower half plane changes the quantity
            {
                FigInx = FindObjectOfType<Right_Controller>().FigInx - FindObjectOfType<GameBuild>().numTimeSteps * FindObjectOfType<GameBuild>().numQuants + FindObjectOfType<GameBuild>().numTimeSteps;
                GameObject parentObject = FindObjectOfType<GameBuild>().FlowFigures[FindObjectOfType<Right_Controller>().FigInx];
                TextMeshPro positionText = parentObject.GetComponentInChildren<Set_Text_Position>().textComponent;
                positionText.color = new Color(0, 0, 0, 1);
                //When the quantity is changed, text appears above the isosurface telling you what quantity you switched to
                GameObject.Find("Controller (right)").GetComponent<Right_Controller>().StopCoroutine("FadeOutText");
                GameObject.Find("Controller (right)").GetComponent<Right_Controller>().StartCoroutine("FadeOutText", positionText);
                counter_for_text += 1;
            }
            else if (touchpoints.y < 0 && FigInx <= FindObjectOfType<GameBuild>().numTimeSteps * (FindObjectOfType<GameBuild>().numQuants - 1) - 1)
            {
                FigInx = FigInx + FindObjectOfType<GameBuild>().numTimeSteps;
                GameObject parentObject = FindObjectOfType<GameBuild>().FlowFigures[FigInx];
                TextMeshPro positionText = parentObject.GetComponentInChildren<Set_Text_Position>().textComponent;
                positionText.color = new Color(0, 0, 0, 1);
                GameObject.Find("Controller (right)").GetComponent<Right_Controller>().StopCoroutine("FadeOutText");
                GameObject.Find("Controller (right)").GetComponent<Right_Controller>().StartCoroutine("FadeOutText", positionText);
                counter_for_text += 1;
            }
        }

        //Every time the touchpad is pressed, we check to see if the user is holding down the touchpad. If the user holds it for more than 1 second, ContinuousFigures() will start
        if (controller.GetPress(SteamVR_Controller.ButtonMask.Touchpad))
        {
            StartCoroutine(ContinuousFigures());
        }


        if (controller.GetPressUp(SteamVR_Controller.ButtonMask.Touchpad))
        {
            counter = 0;
        }
    }

    //Function to cycle through time steps continuously
    IEnumerator ContinuousFigures()
    { 
        yield return new WaitForSecondsRealtime(1.0f); //Start the function if we hold down the trackpad for more 1 second or more
        if (controller.GetPress(SteamVR_Controller.ButtonMask.Touchpad))
        { 
            Vector2 touchpoints = controller.GetAxis(Valve.VR.EVRButtonId.k_EButton_Axis0);
            counter += 2 * Time.deltaTime; //This gives the speed at which the time steps change, i.e. how fast the time steps appear to move
            if (touchpoints.y >= 0.0f) //Pressing the upper half plane will change time steps continuously
            {
                if (counter >= DeltaStep && (FigInx + 1) % FindObjectOfType<GameBuild>().numTimeSteps == 0) 
                {
                    FigInx = FigInx - (FindObjectOfType<GameBuild>().numTimeSteps - 1); 
                    counter = 0; 
                }
                else if (counter >= DeltaStep && (FigInx + 1) % FindObjectOfType<GameBuild>().numTimeSteps != 0)
                {
                    FigInx = FigInx + 1; 
                    counter = 0;
                }
            }
            else if (touchpoints.y < 0.0f) //Pressing the lower half plane will change the quantity continuously
            {
                if (counter >= DeltaStep)
                {
                    if (FigInx == 0 || FigInx % FindObjectOfType<GameBuild>().numTimeSteps == 0)
                    {
                        FigInx = FigInx + FindObjectOfType<GameBuild>().numTimeSteps - 1;
                        counter = 0;
                    }
                    else if (FigInx != 0 || FigInx % FindObjectOfType<GameBuild>().numTimeSteps != 0)
                    {
                        FigInx = FigInx - 1;
                        counter = 0;
                    }
                }
            }
        }
    }


    //When the quantity changes and the text above the isosurface appears, this makes the text fade out to eventually become invisible
    public IEnumerator FadeOutText(TextMeshPro words)
    {
        float progress = 0.0f;
        float rate = 0.05f / fadeOutTime;

        while (progress < 1.0)
        {
            words.color = new Color(0, 0, 0, Mathf.Lerp(words.color.a, 0, progress));
            progress += rate * Time.deltaTime;
            yield return null;
        }
    }

    //Note: An IEnumerator function is a way for Unity to "pause" the game such that you can perform some continuous action.

}