#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());

	// Let's update the elements of the reference set of additional requirements and PVC additional requirements. 
	UpdateAdditionalPropertyFields(ThisObject, "Catalog_Incidents");

EndProcedure

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
		PropertiesSet = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

// Adapted version of property Management.Before writing a ViewObject()
//
// Parameters:
//  IncidentKind - CatalogObject.IncidentKinds
//  ObjectWithPropertiesName - String - Name of an object with properties
//  Property requisitanabor name - String - Name of the Attribute of the property set
//  The end of the name is the string - The end of the name
//  NeedSetOfProperties - Boolean - Need a set of properties
Procedure UpdateAdditionalPropertyFields(IncidentKind,
                                  ObjectWithPropertiesName,
                                  NeedSetOfProperties = True) Export
	
	SetPrivilegedMode(True);
	
	PropertiesSet   = IncidentKind["PropertiesSet"];
	SetParent = PropertyManager.PropertiesSetByName(ObjectWithPropertiesName);
	
	// Updates to the names of a set of properties
	If ValueIsFilled(PropertiesSet) Then
		
		OldSetProperties = Common.ObjectAttributesValues(
			PropertiesSet, "Description, Parent, DeletionMark");
		
		If OldSetProperties.Description    = IncidentKind.Description
		   And OldSetProperties.DeletionMark = IncidentKind.DeletionMark
		   And OldSetProperties.Parent        = SetParent Then
			
			Return;
		EndIf;
		
		If OldSetProperties.Parent = SetParent Then
			LockDataForEdit(PropertiesSet);
			PropertySetObject = PropertiesSet.GetObject();
		Else
			PropertySetObject = PropertiesSet.Copy();
		EndIf;
		
	ElsIf NeedSetOfProperties Then
		PropertySetObject = Catalogs.AdditionalAttributesAndInfoSets.CreateItem();
		PropertySetObject.Used = True;
	Else
		PropertySetObject = Undefined;
	EndIf;
	
	If PropertySetObject <> Undefined Then 
		PropertySetObject.Description    = IncidentKind.Description;
		PropertySetObject.DeletionMark = ?(NeedSetOfProperties, IncidentKind.DeletionMark, True);;
		PropertySetObject.Parent        = SetParent;
		PropertySetObject.Write();
	EndIf;
	
	IncidentKind["PropertiesSet"] = ?(NeedSetOfProperties, PropertySetObject.Ref, Undefined);
	
	// Updating the names of non-common additional details and information.
	If Not ValueIsFilled(PropertiesSet) Then
		Return;
	EndIf;
	
	ChangedNames = New Map;
	
	Query = New Query;
	Query.SetParameter("PropertiesSet", PropertiesSet);
	Query.Text =
	"SELECT
	|	Properties.Ref AS Ref,
	|	Properties.PropertiesSet.Description AS DescriptionOfSet,
	|	Properties.PropertiesSet.DeletionMark AS DeletionMarkOfSet,
	|	Properties.IsAdditionalInfo
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|WHERE
	|	Properties.PropertiesSet = &PropertiesSet
	|	AND CASE
	|			WHEN Properties.Description <> Properties.Title + "" ("" + Properties.PropertiesSet.Description + "")""
	|				THEN TRUE
	|			WHEN Properties.DeletionMark <> Properties.PropertiesSet.DeletionMark
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
	PropertiesSelection = Query.Execute().Select();
	While PropertiesSelection.Next() Do
		
		LockDataForEdit(PropertiesSelection.Ref);
		
		Object = PropertiesSelection.Ref.GetObject(); // ChartOfCharacteristicTypesObject.AdditionalAttributesAndInfo
		
		OldName_ = Object.Description;
		Object.Description = Object.Title + " (" + String(PropertiesSelection.DescriptionOfSet) + ")";
		Object.DeletionMark = PropertiesSelection.DeletionMarkOfSet;
		
		Object.AdditionalProperties.Insert("DoNotUpdateTitleTemplates");
		Object.Write();
		
		If Not PropertiesSelection.IsAdditionalInfo Then
			ChangedNames.Insert(
				"[" + OldName_ + "]", "[" + Object.Description + "]");
		EndIf;
		
	EndDo;
	
	// Renaming in name templates
	If ChangedNames.Count() = 0 Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
