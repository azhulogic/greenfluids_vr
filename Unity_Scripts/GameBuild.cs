//
//Purpose: Fills the scene with our isosurfaces
//
//======================================================

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameBuild : MonoBehaviour
{
    public GameObject[] FlowFigures;
    public int numTimeSteps;
    public int numQuants;

    [HideInInspector]
    public int Size;
    [HideInInspector]
    public float PosX;
    [HideInInspector]
    public float PosY;
    [HideInInspector]
    public float PosZ;
    [HideInInspector]
    public float AngX;
    [HideInInspector]
    public float AngY;
    [HideInInspector]
    public float AngZ;

    public string Prefix1 = "Z_Vorticity_";

    public string Prefix2 = "X_Vel_";

    public string Prefix3 = "Y_Vel_";

    //The Awake function is called right when you start the game, so it is used as a way to initialize anything you want to.
    void Awake()
    {
        //FlowFigures is a variable that will hold all the isosurfaces. So here, we are just setting the size of the of FlowFigures
        FlowFigures = new GameObject[numTimeSteps * numQuants];


        //We are transferring all the isosurfaces into the FlowFigures variable.
        //We have three quantities which are x velocity, y velocity, and z vorticity (don't worry about what those mean) and 24 time steps. So the z vorticity quantity takes up the first 24 slots of FlowFigures etc.
        for (int i = 0; i < numTimeSteps; i++)
        {
            FlowFigures[i] = GameObject.Find(Prefix1 + "0" + (i + 1).ToString()); //Fill the FlowFigures array with our data, where each index holds one GameObject
            FlowFigures[i + numTimeSteps] = GameObject.Find(Prefix2 + (i + 1).ToString());
            FlowFigures[i + 2 * numTimeSteps] = GameObject.Find(Prefix3 + (i + 1).ToString());
        }

        //Setting the scale, angle, and position that we want the isosurfaces to be
        Size = 150;
        AngX = 0;
        AngY = 0;
        AngZ = 0;
        PosX = -1;
        PosY = 1;
        PosZ = 0;

        //Assigning each isosurface the scale, angle, and position values
        foreach (GameObject figure in FindObjectOfType<GameBuild>().FlowFigures)
        {
            figure.transform.localScale = new Vector3(Size, Size, Size);
            figure.transform.localPosition = new Vector3(PosX, PosY, PosZ);
            figure.transform.localEulerAngles = new Vector3(AngX, AngY, AngZ);
        }
    }

    //The Update function is called every frame while the game is playing. 
    void Update()
    {

    }
}
