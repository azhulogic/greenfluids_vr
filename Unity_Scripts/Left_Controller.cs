//
//Purpose: Contains the functions of the left controller.
//
//======================================================

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class Left_Controller : MonoBehaviour
{
    public Valve.VR.EVRButtonId trigger = Valve.VR.EVRButtonId.k_EButton_SteamVR_Trigger;
    [HideInInspector]
    public bool triggerButtonDown = false;

    private Valve.VR.EVRButtonId grip = Valve.VR.EVRButtonId.k_EButton_Grip;
    [HideInInspector]
    public bool gripButtonDown = false;

    private Valve.VR.EVRButtonId menu = Valve.VR.EVRButtonId.k_EButton_ApplicationMenu;
    
    [HideInInspector]
    public bool menuButtonDown = false;

    private int trackpadCounter = 0;

    //Gaining access to the controller location and buttons
    public SteamVR_Controller.Device controller { get { return SteamVR_Controller.Input((int)trackedObj.index); } }
    private SteamVR_TrackedObject trackedObj;



    // Called Only Once for "Set-Up"
    void Start()
    {
        trackedObj = GetComponent<SteamVR_TrackedObject>();
    }

    //These will be used in the GrabObject() and ReleaseObject() functions
    public GameObject collidingObject1;
    public GameObject collidingObject2;
    public GameObject objectInHand;
    public GameObject objectInHand2;


    void OnTriggerEnter(Collider other)
    {
        if (!other.GetComponent<Rigidbody>())
        {
            return;
        }
        collidingObject1 = other.gameObject;
    }


    // Update is called once per frame
    void Update()
    {

        if (controller == null)
        {
            Debug.Log("Left Controller Not Yet Initialized!");
            return;
        }

        menuButtonDown = controller.GetPressDown(menu);
        GameObject colorPicker = GameObject.Find("ColorPicker");

        //The menu button acts as an eraser. But instead of erasing, we are removing the individual objects from the 'lines' array in the DrawLineManager script
        if (menuButtonDown && FindObjectOfType<DrawLineManager>().lines.Count != 0)
        {
            Destroy(FindObjectOfType<DrawLineManager>().lines[FindObjectOfType<DrawLineManager>().lines.Count - 1]);
            FindObjectOfType<DrawLineManager>().lines.RemoveAt(FindObjectOfType<DrawLineManager>().lines.Count - 1);
        }

        //When the left trigger is held down, we take control of the current isosurface with the movement of the left controller
        if (FindObjectOfType<Right_Controller>().controller.GetPress(FindObjectOfType<Right_Controller>().trigger) == false)
        {
            if (controller.GetPressDown(SteamVR_Controller.ButtonMask.Trigger))
            {
                if (collidingObject1) 
                {
                    GrabObject();
                }
            }
        }

        //Release the object from the left controller when the trigger is released
        if (controller.GetPressUp(SteamVR_Controller.ButtonMask.Trigger))
        {
            if (objectInHand)
            {
                ReleaseObject();
            }
        }

        //Activate or deactivate the color picker by clicking the touchpad by increasing or decreasing its size
        if (controller.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad))
        {
            if (trackpadCounter % 2 == 0)
            {
                colorPicker.transform.localScale = new Vector3(0, 0, 0);
                trackpadCounter++;
            }
            else
            {
                colorPicker.transform.localScale = new Vector3(0.003f, 0.003f, 0.003f);
                trackpadCounter++;
            }
        }
    }

    //Function to move the object around in accordance with how the user moves the controller
    private void GrabObject() 
    {
        collidingObject1 = FindObjectOfType<GameBuild>().FlowFigures[FindObjectOfType<Right_Controller>().FigInx];
        objectInHand = collidingObject1;
        objectInHand.transform.SetParent(this.transform, true); //The isosurface becomes a child object of the controller while retaining its current position and angle
        objectInHand.GetComponent<Rigidbody>().isKinematic = true;
        if (FindObjectOfType<DrawLineManager>().go != null) //We also take control of all the drawings that the user has created (if there are any)
        {
            objectInHand2 = FindObjectOfType<DrawLineManager>().go;
            objectInHand2.transform.SetParent(this.transform, true);
            foreach (GameObject line in FindObjectOfType<DrawLineManager>().lines)
            {
                line.transform.SetParent(objectInHand2.transform, true);
            }

        }

    }

    //Function to release the controllers ability to move the object around
    private void ReleaseObject()
    {
        objectInHand.GetComponent<Rigidbody>().isKinematic = false;
        objectInHand.transform.SetParent(null); //The current isosurface is no longer a child object of the controller
        foreach (GameObject figure in FindObjectOfType<GameBuild>().FlowFigures) //All of the other isosurfaces in FlowFigures will hold the same position and rotation as the current isosurface
        {
            figure.transform.localPosition = objectInHand.transform.localPosition;
            figure.transform.localEulerAngles = objectInHand.transform.localEulerAngles;
        }
        if (FindObjectOfType<DrawLineManager>().go != null) 
        {
            objectInHand2.transform.SetParent(null); //The drawings are no longer a child object of the left controller
            foreach (GameObject line in FindObjectOfType<DrawLineManager>().lines)
            {
                line.transform.SetParent(null);
            }
        }
    }
}