
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return;
	EndIf;
	
	AssetID = "";
	
	InitializeCatalog();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	AttributesNotToCheck = New Array;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ObjectsOfOperation(
									ThisObject, AuxiliaryAttributes());
									
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	UseRMManagement = GetFunctionalOption("UseRMManagement");
	
	If UseRMManagement Then
		
		If OSType = Enums.FATypes.Asset 
			Or OSType = Enums.FATypes.Node
			Or OSType = Enums.FATypes.CapitalExpenditureInLeasedAssets Then
			
			// The standard filling verification mechanism is used only to verify standard details: "Name",
			// "Code", "Status" and "DataSvedeniy" Verification of details, additional details and tabular parts is initiated from the object form.
		
			CheckedAttributes.Clear();
			CheckedAttributes.Add("Description");
			CheckedAttributes.Add("Status");
			CheckedAttributes.Add("DateOfLastEdit");
			
		EndIf;
		
	Else
		
		
		AttributesNotToCheck.Add("Class");
		AttributesNotToCheck.Add("Subclass");
		AttributesNotToCheck.Add("RunningTimeRecordingParameters.RunningTimeValue");
		AttributesNotToCheck.Add("RunningTimeRecordingParameters.AssignedResource");
		AttributesNotToCheck.Add("RunningTimeRecordingParameters.Source");
		
		If Not GetFunctionalOption("EnterpriseManagement") Then
			AttributesNotToCheck.Add("WorkCenters.WorkCenter");
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	InitializeAdditionalPropertiesForRecord();
	
	If AdditionalProperties.ItemSubmittedForEditing Then
		
		DateOfLastEdit = CurrentSessionDate();
		
	EndIf;
	
	If AdditionalProperties.UpdateFullName Then
		
		DescriptionFull = Description;
		
	EndIf;
	FillInInventoryNumberOfDepreciationComponentNode(Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UpdateNodeAccessories(Cancel);
	UpdateNodeMovementHistory(Cancel);
	
	Return; // Empty handler in UT and KA
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeCatalog()
	
	Status = Enums.AssetStatuses.IsBeingEdited;
	DateOfLastEdit = CurrentSessionDate();
	
EndProcedure

Procedure InitializeAdditionalPropertiesForRecord()
	
	If AdditionalProperties.Property("InitializedForWriting") Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("UseRMManagement", GetFunctionalOption("UseRMManagement"));
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("ItemSubmittedForEditing", False);
	AdditionalProperties.Insert("UpdateNodeSubordinates", False);
	AdditionalProperties.Insert("UpdateNodeAccessories", False);
	AdditionalProperties.Insert("UpdateFullName", IsBlankString(DescriptionFull));
	AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
	If AdditionalProperties.UseRMManagement Then
		
		If Not AdditionalProperties.IsNew Then
			DetailsBeforeRecording = Common.ObjectAttributesValues(Ref, "Status, Description, DescriptionFull");
			AdditionalProperties.ItemSubmittedForEditing = (
				DetailsBeforeRecording.Status <> Enums.AssetStatuses.IsBeingEdited
				And DetailsBeforeRecording.Status <> Status);
			AdditionalProperties.UpdateNodeSubordinates = (
				DetailsBeforeRecording.Status = Enums.AssetStatuses.IsBeingEdited
				And DetailsBeforeRecording.Status <> Status);
			AdditionalProperties.UpdateNodeAccessories = (DetailsBeforeRecording.Description <> Description);
			AdditionalProperties.UpdateFullName = (
				IsBlankString(DescriptionFull)
				Or (DescriptionFull = DetailsBeforeRecording.DescriptionFull
					And DetailsBeforeRecording.DescriptionFull = DetailsBeforeRecording.Description));
		EndIf;
		
	EndIf;
	AdditionalProperties.Insert("InitializedForWriting");
	
EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure; 
	AuxiliaryAttributes.Insert("UseLocal", GetFunctionalOption("UseLocal"));
	AuxiliaryAttributes.Insert("UseRMManagement", GetFunctionalOption("UseRMManagement"));
	AuxiliaryAttributes.Insert("UseProduction", GetFunctionalOption("UseProduction"));
	AuxiliaryAttributes.Insert("UseAccountingOfPreciousMaterial", False);
	
	UseOfSubclasses = False;
	UseOfSubclasses = RMManagementServerCall.UseOfSubclasses(Class); 
	AuxiliaryAttributes.Insert("UseOfSubclasses", UseOfSubclasses);
	
	AssetsLocalization.AddAuxiliaryDetails(AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;
	
EndFunction
Procedure FillInInventoryNumberOfDepreciationComponentNode(Cancel)
	
	If Not Cancel
		And Not IsFolder
		And IsNew()
		And (OSType = Enums.FATypes.Node
			Or OSType = Enums.FATypes.DepreciationComponent) Then
		
		If Not ValueIsFilled(Code) Then
			SetNewCode();
		EndIf;
		
		AssetID = Code;
	
	EndIf;
	
EndProcedure
Procedure UpdateNodeAccessories(Cancel)
	
	If IsFolder
		Or Not AdditionalProperties.UpdateNodeAccessories 
		Or Cancel Then
		Return;
	EndIf;
			
	SetPrivilegedMode(True);

	StructureOfAdditionalProperties = New Structure;
	StructureOfAdditionalProperties.Insert("IsNew", False);
	StructureOfAdditionalProperties.Insert("WritingFromExternalObject", True);
	StructureOfAdditionalProperties.Insert("FillingValues", Undefined);
	StructureOfAdditionalProperties.Insert("FillingActions", New Structure("FillInAffiliation"));
	StructureOfAdditionalProperties.Insert("FillingInSubordinatesIsRequired", False);
	
	FilterStructure1 = New Structure("Owner", Ref);
	
	Catalogs.SubAssets.FillInByPicking(FilterStructure1, StructureOfAdditionalProperties, Cancel);
	
EndProcedure

Procedure UpdateNodeMovementHistory(Cancel)
	
	If IsFolder
		Or Not AdditionalProperties.UpdateNodeSubordinates 
		Or Cancel Then
		Return;
	EndIf;
			
	SetPrivilegedMode(True);
	
	QueryText = 
	"SELECT
	|	SubAssets.Ref AS Ref,
	|	SubAssets.Parent AS Parent
	|FROM
	|	Catalog.SubAssets AS SubAssets
	|WHERE
	|	SubAssets.Owner = &Asset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Asset", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		RecordSet = InformationRegisters.SubordinationOfSubAssets.CreateRecordSet();
		RecordSet.Filter.Period.Set(DateOfLastEdit);
		RecordSet.Filter.SubAsset_.Set(Selection.Ref);
		
		Record = RecordSet.Add();
		Record.Period = DateOfLastEdit;
		Record.SubAsset_ = Selection.Ref;
		Record.Parent = Selection.Parent;
		Record.Asset = Ref;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
