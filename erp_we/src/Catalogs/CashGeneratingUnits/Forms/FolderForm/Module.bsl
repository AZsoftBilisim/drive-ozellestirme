#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Catalogs.CashGeneratingUnits.RestrictListOfOrganizations(Parameters, Object, Items.Owner);
	//Creating a new group from the list Form of the Catalog opened from the document.
	If Object.Ref = Catalogs.CashGeneratingUnits.EmptyRef() 
			And Parameters.FillingValues.Property("Owner")
			And TypeOf(Parameters.FillingValues.Owner) = Type("ValueList")
			And Parameters.FillingValues.Owner.Count() > 0 Then
				// The owner will be the first of the list, the branch organization specified in the document.
				For Each Owner In Parameters.FillingValues.Owner Do
					Object.Owner = Owner.Value;
					Break;
				EndDo;
	EndIf;
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

EndProcedure

#EndRegion

#Region Private
&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCompanies       = GetFunctionalOption("UseMultipleCompanies");
	
	If Not UseMultipleCompanies Then
		If Not ValueIsFilled(Object.Ref) Then // A new element of the directory.
			Object.Owner = SettingsValueCached.GetDefaultOrganization();
		EndIf;
	EndIf;
	
	Items.Owner.Visible = UseMultipleCompanies;
	
	If Object.Ref <> Catalogs.CashGeneratingUnits.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;
	
EndProcedure
#EndRegion

