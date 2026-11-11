
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SourceSettings = Undefined;
	If Not AdditionalProperties.Property("SourceSettings", SourceSettings) Then
		SourceSettings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(ThisObject);
	EndIf;
	SourceSettings.Used = Not DeletionMark;
	
	DescriptionOfUploadedData = Undefined;
	If Not AdditionalProperties.Property("DescriptionOfUploadedData", DescriptionOfUploadedData) Then
		DescriptionOfUploadedData = ProductDataManagement.DescriptionOfUploadedData(SourceSettings);
	EndIf;
	
	CheckAddRequiredAttributes(DescriptionOfUploadedData);
	
	CheckClearUnusedAttributes(DescriptionOfUploadedData);
	
	If Not IsNew()
			And Common.ObjectAttributeValue(Ref, "DeletionMark") <> DeletionMark Then
		AdditionalProperties.Insert("SourceSettings", SourceSettings);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SourceSettings = Undefined;
	If AdditionalProperties.Property("SourceSettings", SourceSettings) Then
		InformationRegisters.MasterDataImportSettings.RecordSourceSettings(Ref, SourceSettings, True);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Settings = Catalogs.SourcesToImportProductionMasterData.GetStructureOfSettingsFromRepository(
		CopiedObject.SettingsStorage);
	Catalogs.SourcesToImportProductionMasterData.PutSettingsStructureInRepository(
		ThisObject, Settings);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckAddRequiredAttributes(DescriptionOfUploadedData)
	
	For Each KeyAndValue1 In DescriptionOfUploadedData Do
		FilterStructure1 = Common.CopyRecursive(KeyAndValue1.Value.FilterStructure1);
		For Each AttributeGroup In ProductDataManagementClientServer.AttributesGroups() Do
			For Each KeyAndValue2 In KeyAndValue1.Value[AttributeGroup] Do
				If KeyAndValue2.Value.IsRequired Then
					FilterStructure1.Insert("AttributeName", KeyAndValue2.Value.Name);
					If AttributesDetails1.FindRows(FilterStructure1).UBound() = -1 Then
						NewRow = AttributesDetails1.Add();
						FillPropertyValues(NewRow, FilterStructure1);
						Catalogs.SourcesToImportProductionMasterData.InitializeNewRowInAttributesTable(
							NewRow, True);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckClearUnusedAttributes(DescriptionOfUploadedData)
	
	Table = AttributesDetails1.UnloadColumns();
	For Each KeyAndValue In DescriptionOfUploadedData Do
		For Each String In AttributesDetails1.FindRows(KeyAndValue.Value.FilterStructure1) Do
			If String.MethodToSetValue.IsEmpty()
				Or String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.DontUse Then
				Continue;
			EndIf;
			For Each AttributeGroup In ProductDataManagementClientServer.AttributesGroups() Do
				If KeyAndValue.Value[AttributeGroup].Property(String.AttributeName) Then
					NewRow = Table.Add();
					FillPropertyValues(NewRow, String);
					If NewRow.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm Then
						NewRow.Value = Undefined;
					Else
						NewRow.ValueCalculationAlgorithm = "";
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	AttributesDetails1.Load(Table);
	
EndProcedure

#EndRegion

#EndIf
