///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.DataItemType) = Type("Type") Then
		MetadataObject = Metadata.FindByType(Parameters.DataItemType);
	Else
		Parameters.DataItemType = TypeOf(Parameters.DataItemType);
	EndIf;
	
	If MetadataObject = Undefined
	 Or Not Common.IsRegister(MetadataObject) Then
		
		ErrorText = NStr("vi = 'Để mở biểu mẫu, cần truyền tham số';
						|ru = 'Для открытия формы нужно указать параметр';
						|en = 'A parameter is required to open the form'; fa = 'A parameter is required to open the form';
						|it = 'A parameter is required to open the form';
						|pl = 'A parameter is required to open the form';
						|tr = 'Formu açabilmek için parametre belirtilmelidir'");
		ForAdministrator = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để mở biểu mẫu %1, cần truyền kiểu khóa bản ghi của biểu ghi
			           |trong tham số biểu mẫu %2, nhưng đã truyền kiểu ""%3"".';
			           |ru = 'Для открытия формы %1 нужно передать тип ключа записи регистра
			           |в параметре формы %2, а передан тип ""%3"".';
			           |en = 'To open form %1, the record key type of the register
			           |in the form parameter %2 is expected. The actual type is ""%3"".'; fa = 'To open form %1, the record key type of the register
			           |in the form parameter %2 is expected. The actual type is ""%3"".';
			           |it = 'To open form %1, the record key type of the register
			           |in the form parameter %2 is expected. The actual type is ""%3"".';
			           |pl = 'To open form %1, the record key type of the register
			           |in the form parameter %2 is expected. The actual type is ""%3"".';
			           |tr = 'Form %1''i açmak için form %2 parametresinde kayıt 
			           | kayıt anahtarının anahtar türünü geçirmemiz gerekir ve geçirilen tür ""%3"".'"),
			"SelectRegisterRow",
			"DataItemType",
			Parameters.DataItemType);
		
		Raise(ErrorText,,, ForAdministrator);
	EndIf;
	
	VerifyAccessRights("View", MetadataObject);
	
	FullName = MetadataObject.FullName();
	StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, FullName,, False);
	
	Source.CustomQuery = False;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = "";
	ListProperties.MainTable = FullName;
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.Source, ListProperties);
	
	Source.AutoFillAvailableFields = True;
	Source.GetInvisibleFieldPresentations = True;
	
	FieldList = New ValueList;
	For Each FieldDetails In Source.SettingsComposer.Settings.SelectionAvailableFields.Items Do
		FieldName = String(FieldDetails.Field);
		If FieldName = "PointInTime"
		 Or FieldName = "Active"
		 Or FieldName = "RecordType"
		 Or FieldDetails.Type.ContainsType(Type("ValueStorage")) Then
			Continue;
		EndIf;
		FieldList.Add(FieldName);
	EndDo;
	
	OrderRegisterFields(MetadataObject, FieldList);
	
	For Each ListItem In FieldList Do
		FieldName = ListItem.Value;
		NewItem = Items.Add("Source" + FieldName, Type("FormField"), Items.Source);
		NewItem.DataPath = "Source." + FieldName;
		NewItem.Type = FormFieldType.LabelField;
	EndDo;
	
	Items.StandardPicture.Visible = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OrderRegisterFields(MetadataObject, FieldList)
	
	IsInformationRegister    = Common.IsInformationRegister(MetadataObject);
	IsAccountingRegister = Common.IsAccountingRegister(MetadataObject);
	IsCalculationRegister     = Common.IsCalculationRegister(MetadataObject);
	
	IndexOf = 0;
	
	If IsCalculationRegister Then
		ShiftElement("RegistrationPeriod", FieldList, IndexOf, 1);
	Else
		ShiftElement("Period", FieldList, IndexOf, 1);
	EndIf;
	
	If Not IsInformationRegister
	 Or MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		
		ShiftElement("Recorder", FieldList, IndexOf, 1);
		ShiftElement("LineNumber", FieldList, IndexOf, 1);
	EndIf;
	
	If IsCalculationRegister Then
		ShiftElement("CalculationType", FieldList, IndexOf, 1);
		ShiftElement("ActionPeriod", FieldList, IndexOf, 1);
		ShiftElement("BegOfActionPeriod", FieldList, IndexOf, 1);
		ShiftElement("EndOfActionPeriod", FieldList, IndexOf, 1);
		ShiftElement("BegOfBasePeriod", FieldList, IndexOf, 1);
		ShiftElement("EndOfBasePeriod", FieldList, IndexOf, 1);
		ShiftElement("ReversingEntry", FieldList, IndexOf, 1);
	EndIf;
	
	ShiftCollectionItems(MetadataObject.StandardAttributes, FieldList, IndexOf,, 1);
	If IsAccountingRegister Then
		ShiftCollectionItems(MetadataObject.StandardAttributes, FieldList, IndexOf, True, 1);
	EndIf;
	
	IndexOf = FieldList.Count() - 1;
	
	ShiftCollectionItems(MetadataObject.Attributes, FieldList, IndexOf);
	
	ShiftCollectionItems(MetadataObject.Resources, FieldList, IndexOf);
	If IsAccountingRegister Then
		ShiftCollectionItems(MetadataObject.Resources, FieldList, IndexOf, True);
	EndIf;
	
	If IsAccountingRegister Then
		ShiftCollectionItems(MetadataObject.Dimensions, FieldList, IndexOf, True);
	EndIf;
	ShiftCollectionItems(MetadataObject.Dimensions, FieldList, IndexOf);
	
EndProcedure

&AtServer
Procedure ShiftCollectionItems(FieldsCollection, FieldList, SharedIndex,
			HasBalanceFlag = False, IndexShift = -1)
	
	If IndexShift = -1 Then
		IndexOf = FieldsCollection.Count() - 1;
		While IndexOf >= 0 Do
			ShiftCollectionItem(FieldsCollection.Get(IndexOf),
				FieldList, SharedIndex, HasBalanceFlag, IndexShift);
			IndexOf = IndexOf - 1;
		EndDo;
	Else
		For Each CollectionField In FieldsCollection Do
			ShiftCollectionItem(CollectionField,
				FieldList, SharedIndex, HasBalanceFlag, IndexShift);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShiftCollectionItem(CollectionField, FieldList, SharedIndex, HasBalanceFlag, IndexShift)
	
	If HasBalanceFlag Then
		ShiftElement(CollectionField.Name + "Dr", FieldList, SharedIndex, IndexShift);
		ShiftElement(CollectionField.Name + "Cr", FieldList, SharedIndex, IndexShift);
	Else
		ShiftElement(CollectionField.Name, FieldList, SharedIndex, IndexShift);
	EndIf;
	
EndProcedure

&AtServer
Procedure ShiftElement(FieldName, FieldList, IndexOf, IndexShift = -1)
	
	ListItem = FieldList.FindByValue(FieldName);
	
	If ListItem = Undefined Or ListItem.Check Then
		Return;
	EndIf;
	
	Move = IndexOf - FieldList.IndexOf(ListItem);
	
	FieldList.Move(ListItem, Move);
	ListItem.Check = True;
	
	IndexOf = IndexOf + IndexShift;
	
EndProcedure

#EndRegion
