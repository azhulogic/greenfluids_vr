// Purpose: Text appears above the game object when the user changes quantity. This script sets the position of that text to just above the game object.
//
// Implementation: Attach this script to each game object as a component.

//Note to Ibrahima: You don't really have to worry about this script. I only put it in here because I make significant reference to it in the Right_Controller script.

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using System;

public class Set_Text_Position : MonoBehaviour
{
    [HideInInspector]
    public TextMeshPro textComponent;
   
    private string quantity1 = "Z Vorticity";
    
    private string quantity2 = "X Velocity";
    
    private string quantity3 = "Y Velocity";


    void Start()
    {
        textComponent = GetComponent<TextMeshPro>();

        
        if (0 <= Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) && Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) < 24)
        {
            textComponent.text = quantity1;
            textComponent.color = new Color(0, 0, 0, 0);
            textComponent.rectTransform.localPosition = new Vector3(transform.parent.gameObject.transform.localPosition.x, transform.parent.gameObject.transform.localPosition.y + 0.006f, transform.parent.gameObject.transform.localPosition.z + 0.008f);
            textComponent.rectTransform.rotation = Quaternion.Euler(transform.parent.gameObject.transform.localEulerAngles.x, transform.parent.gameObject.transform.localEulerAngles.y - 90f, transform.parent.gameObject.transform.localEulerAngles.z);
            textComponent.rectTransform.localScale = new Vector3(0.001f, 0.001f, 0.001f);
        }
        else if (24 <= Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) && Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) < 48)
        {
            textComponent.text = quantity2;
            textComponent.color = new Color(0, 0, 0, 0);
            textComponent.rectTransform.localPosition = new Vector3(transform.parent.gameObject.transform.localPosition.x, transform.parent.gameObject.transform.localPosition.y + 0.006f, transform.parent.gameObject.transform.localPosition.z + 0.008f);
            textComponent.rectTransform.rotation = Quaternion.Euler(transform.parent.gameObject.transform.localEulerAngles.x, transform.parent.gameObject.transform.localEulerAngles.y - 90f, transform.parent.gameObject.transform.localEulerAngles.z);
            textComponent.rectTransform.localScale = new Vector3(0.001f, 0.001f, 0.001f);
        }
        else if (48 <= Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) && Array.IndexOf(FindObjectOfType<GameBuild>().FlowFigures, transform.parent.gameObject) < 72)
        {
            textComponent.text = quantity3;
            textComponent.color = new Color(0, 0, 0, 0);
            textComponent.rectTransform.localPosition = new Vector3(transform.parent.gameObject.transform.localPosition.x, transform.parent.gameObject.transform.localPosition.y + 0.006f, transform.parent.gameObject.transform.localPosition.z + 0.008f);
            textComponent.rectTransform.rotation = Quaternion.Euler(transform.parent.gameObject.transform.localEulerAngles.x, transform.parent.gameObject.transform.localEulerAngles.y - 90f, transform.parent.gameObject.transform.localEulerAngles.z);
            textComponent.rectTransform.localScale = new Vector3(0.001f, 0.001f, 0.001f);
        }
    }

    // Update is called once per frame
    void Update()
    {

    }
}
