//
//Purpose: Contains the functionality to "draw" with the controller
//
//======================================================


using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
public class DrawLineManager : MonoBehaviour
{
    public Material lMat;

    public SteamVR_TrackedObject trackedObj;

    public int gripButtonCounter = 0;

    public GameObject go;

    public MeshLineRenderer currLine;

    private int numClicks = 0;

    public List<GameObject> lines;

    void Start()
    {
        //lines will hold all of the drawings that we create in the scene
        lines = new List<GameObject>();
    }

    void Update()
    {
        SteamVR_Controller.Device device = SteamVR_Controller.Input((int)trackedObj.index);

        if (device == null)
        {
            Debug.Log("Right Controller Not Yet Initialized!");
            return;
        }

        if (device.GetTouchDown(SteamVR_Controller.ButtonMask.Grip))
        {
            gripButtonCounter++; 
            //When a drawing is made, Unity automatically creates an object called NewObject. We add this to the lines List so that we have to capability to erase it
            go = new GameObject("NewObject");
            go.AddComponent<MeshFilter>();
            go.AddComponent<MeshRenderer>();
            currLine = go.AddComponent<MeshLineRenderer>();

            lines.Add(go);

            currLine.lmat = new Material(lMat);
            //Can change the width of the line if the user wants it smaller or larger
            currLine.setWidth(.01f);
        }
        else if (device.GetTouch(SteamVR_Controller.ButtonMask.Grip)) 
        {
            //When we hold down the grip button, this will continuously add points to the already existing drawing
            currLine.AddPoint(trackedObj.transform.position); 
            numClicks++;
        }
        else if (device.GetTouchUp(SteamVR_Controller.ButtonMask.Grip))
        {
            numClicks = 0;
            currLine = null;
        }

        //Unity will not go back to the default color (black) each time we let go of the grip button. Rather, Unity will maintain the last used color as the default color
        if (currLine != null)
        {
            currLine.lmat.color = ColorManager.Instance.GetCurrentColor();
        }

    }
}
