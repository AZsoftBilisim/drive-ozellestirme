#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Procedure for initializing additional node properties for subsequent recording
//
// Parameters:
// 		ValuesOfAdditionalProperties - Structure - Structure of additional properties for recording an object.
//
Procedure InitializeAdditionalPropertiesForRecord(ValuesOfAdditionalProperties = Undefined) Export
	
	If AdditionalProperties.Property("InitializedForWriting") Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("IsSubordinateDocument", ValueIsFilled(Parent));
	AdditionalProperties.Insert("CurrentStatus_", Status = Enums.AssetStatuses.Disposed);
	AdditionalProperties.Insert("UpdateFullName", IsBlankString(DescriptionFull));
	
	If ValuesOfAdditionalProperties = Undefined Then
		
		AdditionalProperties.Insert("WritingFromExternalObject", False);
		AdditionalProperties.Insert("FillingValues", Undefined);
		AdditionalProperties.Insert("FillingActions", Undefined);
		
		AdditionalProperties.Insert("FillingInSubordinatesIsRequired", False);
		AdditionalProperties.Insert("ValuesForFillingInSubordinates", New Structure);
		AdditionalProperties.Insert("ActionsForSubordinates", New Structure);
		
		If AdditionalProperties.IsNew Then
			
			AdditionalProperties.Insert(
				"DetailsBeforeRecording",
				New Structure("Description, DescriptionFull, Owner, Parent, Status"));
			
			FillPropertyValues(AdditionalProperties.DetailsBeforeRecording, ThisObject);
			
		Else
			
			AdditionalProperties.Insert(
				"DetailsBeforeRecording",
				Common.ObjectAttributesValues(Ref, "Description, DescriptionFull, Owner, Parent, Status"));
			
		EndIf;
		
		DetailsBeforeRecording = AdditionalProperties.DetailsBeforeRecording; // Structure - contains properties: Name
		
		AdditionalProperties.UpdateFullName = (
			IsBlankString(DescriptionFull)
			Or (DescriptionFull = DetailsBeforeRecording.DescriptionFull
				And DetailsBeforeRecording.DescriptionFull = DetailsBeforeRecording.Description));
		
		If AdditionalProperties.IsSubordinateDocument Then
			
			AdditionalProperties.Insert(
				"ParentAttributes",
				Common.ObjectAttributesValues(Parent, "Status"));
			
			AdditionalProperties.Insert(
				"TakeStatusFromParent",
				AdditionalProperties.ParentAttributes.Status = Enums.AssetStatuses.Disposed);
			
			AdditionalProperties.Insert(
				"CurrentStatus_",
				AdditionalProperties.TakeStatusFromParent);
			
		EndIf;
		
	Else
		
		TMCommonUseClientServer.SupplementStructure(AdditionalProperties, ValuesOfAdditionalProperties, True);
		
	EndIf;
	
	AdditionalProperties.Insert("InitializedForWriting");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillBasedOnStructure(FillingData);
		
	EndIf;
	
	InitializeCatalog();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeCatalog();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SetPrivilegedMode(True);
	
	InitializeAdditionalPropertiesForRecord();
	
	If AdditionalProperties.WritingFromExternalObject Then
		BeforeWritingFromExternalObject(Cancel);
		Return;
	EndIf;
	
	If AdditionalProperties.UpdateFullName Then
		
		DescriptionFull = Description;
		
	EndIf;
	
	If AdditionalProperties.IsSubordinateDocument And AdditionalProperties.TakeStatusFromParent Then
		If AdditionalProperties.ParentAttributes.Status <> Status Then
			Status = AdditionalProperties.ParentAttributes.Status;
		EndIf;
		
	EndIf;
	
	If AdditionalProperties.IsNew Then
		
		FillInAffiliation();
		
	Else
		
		If AdditionalProperties.DetailsBeforeRecording.Description <> Description Then
			
			FillInAffiliation();
			
			AdditionalProperties.FillingInSubordinatesIsRequired = True;
			AdditionalProperties.ActionsForSubordinates.Insert("FillInAffiliation");
			
		EndIf;
		
		If AdditionalProperties.DetailsBeforeRecording.Status <> Status
			And AdditionalProperties.CurrentStatus_ Then
			
			AdditionalProperties.FillingInSubordinatesIsRequired = True;
			AdditionalProperties.ValuesForFillingInSubordinates.Insert("Status", Status);
			
		EndIf;
		
		If AdditionalProperties.DetailsBeforeRecording.Owner <> Owner Then
			AdditionalProperties.FillingInSubordinatesIsRequired = True;
			AdditionalProperties.ValuesForFillingInSubordinates.Insert("Owner", Owner);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.WritingFromExternalObject Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If AdditionalProperties.FillingInSubordinatesIsRequired Then
		
		StructureOfAdditionalProperties = New Structure;
		StructureOfAdditionalProperties.Insert("IsNew", False);
		StructureOfAdditionalProperties.Insert("WritingFromExternalObject", True);
		StructureOfAdditionalProperties.Insert("FillingValues", AdditionalProperties.ValuesForFillingInSubordinates);
		StructureOfAdditionalProperties.Insert("FillingActions", AdditionalProperties.ActionsForSubordinates);
		StructureOfAdditionalProperties.Insert("FillingInSubordinatesIsRequired", False);
		
		FilterStructure1 = New Structure("Parent", Ref);
		
		Catalogs.SubAssets.FillInByPicking(FilterStructure1, StructureOfAdditionalProperties, Cancel);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// The standard filling verification mechanism is used only to verify standard details: "Name",
	// "Code" and "Owner" Verification of details, additional details and tabular parts is initiated by the owner (the object
	// of operation) or the form of the node element.
	
	CheckedAttributes.Clear();
	
	CheckedAttributes.Add("Description");
	CheckedAttributes.Add("Owner");
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeCatalog()
	
	Status = Enums.AssetStatuses.InOperation;
	
EndProcedure

Procedure BeforeWritingFromExternalObject(Cancel)
	
	If AdditionalProperties.FillingValues <> Undefined Then
		FillPropertyValues(ThisObject, AdditionalProperties.FillingValues);
	EndIf;
	
	If AdditionalProperties.FillingActions <> Undefined Then
		
		If AdditionalProperties.FillingActions.Property("FillInAffiliation") Then
			
			FillInAffiliation();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillBasedOnStructure(FillingData)
	
	If FillingData.Property("Parent") Then
		ParentAttributes = Common.ObjectAttributesValues(FillingData.Parent, "Status");
		FillPropertyValues(ThisObject, ParentAttributes);
	EndIf;
	
EndProcedure

Procedure FillInAffiliation()
	
	Result = "";
	
	Separator = "\";
	
	FullPath = ThisObject.FullDescr();
	FullPath = StrReplace(FullPath, "/", Chars.LF);
	
	For N1=1 To StrLineCount(FullPath) Do
		Result = Separator + StrGetLine(FullPath, N1) + Result;
	EndDo;
	
	Belonging = Mid(Result, 2) + Separator + String(ThisObject.Owner);
	
EndProcedure

#EndRegion

#EndIf
