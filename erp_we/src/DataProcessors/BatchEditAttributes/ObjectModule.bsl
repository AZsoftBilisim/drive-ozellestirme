///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// For internal use.
Function QueryText(TypesOfObjectsToChange, RestrictSelection = False) Export
	
	MetadataObjects = New Array;
	For Each ObjectName In StrSplit(TypesOfObjectsToChange, ",", False) Do
		MetadataObjects.Add(Metadata.FindByFullName(ObjectName));
	EndDo;
	
	ObjectsStructure = CommonObjectsAttributes(TypesOfObjectsToChange);
	
	Result = "";
	TableAlias = "SpecifiedTableAlias";
	For Each MetadataObject In MetadataObjects Do
		
		If Not IsBlankString(Result) Then
			Result = Result + Chars.LF + Chars.LF + "UNION ALL" + Chars.LF + Chars.LF;
		EndIf;
		
		QueryText = "";
		
		For Each AttributeName In ObjectsStructure.Attributes Do
			If Not IsBlankString(QueryText) Then
				QueryText = QueryText + "," + Chars.LF;
			EndIf;
			QueryText = QueryText + TableAlias + "." + AttributeName + " AS " + AttributeName;
		EndDo;
		
		For Each TabularSection In ObjectsStructure.TabularSections Do
			TabularSectionName = TabularSection.Key;
			QueryText = QueryText + "," + Chars.LF + TableAlias + "." + TabularSectionName + ".(";
			
			AttributesRow = "LineNumber";
			TabularSectionAttributes = TabularSection.Value;
			For Each AttributeName In TabularSectionAttributes Do
				If Not IsBlankString(AttributesRow) Then
					AttributesRow = AttributesRow + "," + Chars.LF;
				EndIf;
				AttributesRow = AttributesRow + TabularSectionName + "." +  AttributeName + " AS " + AttributeName; //@query-part-2
			EndDo;
			QueryText = QueryText + AttributesRow +"
			|)";
		EndDo;
		
		QueryText = "SELECT " + ?(RestrictSelection, "TOP 1001 ", "") 
			+ QueryText + Chars.LF + "

			|FROM
			|	"+ MetadataObject.FullName() + " AS " + TableAlias; //@query-part-1
			
		Result = Result + QueryText;
	EndDo;
		
		
	Return Result;
	
EndFunction

Function CommonObjectsAttributes(ObjectsTypes) Export
	
	MetadataObjects = New Array;
	For Each ObjectName In StrSplit(ObjectsTypes, ",", False) Do
		MetadataObjects.Add(Metadata.FindByFullName(ObjectName));
	EndDo;
	
	Result = New Structure;
	Result.Insert("Attributes", New Array);
	Result.Insert("TabularSections", New Structure);
	
	If MetadataObjects.Count() = 0 Then
		Return Result;
	EndIf;	
		
	CommonAttributesList = ItemsList(MetadataObjects[0].Attributes, False);
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		CommonAttributesList = AttributesIntersection(CommonAttributesList, MetadataObjects[IndexOf].Attributes);
	EndDo;
	
	StandardAttributes = MetadataObjects[0].StandardAttributes;
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		StandardAttributes = AttributesIntersection(StandardAttributes, MetadataObjects[IndexOf].StandardAttributes);
	EndDo;
	For Each Attribute In StandardAttributes Do
		CommonAttributesList.Add(Attribute);
	EndDo;
	
	Result.Attributes = ItemsList(CommonAttributesList);
	
	TabularSections = ItemsList(MetadataObjects[0].TabularSections);
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		TabularSections = SetIntersection(TabularSections, ItemsList(MetadataObjects[IndexOf].TabularSections));
	EndDo;
	
	For Each TabularSectionName In TabularSections Do
		TabularSectionAttributes = ItemsList(MetadataObjects[0].TabularSections[TabularSectionName].Attributes, False);
		For IndexOf = 1 To MetadataObjects.Count() - 1 Do
			TabularSectionAttributes = AttributesIntersection(TabularSectionAttributes, MetadataObjects[IndexOf].TabularSections[TabularSectionName].Attributes);
		EndDo;
		If TabularSectionAttributes.Count() > 0 Then
			Result.TabularSections.Insert(TabularSectionName, ItemsList(TabularSectionAttributes));
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//   Collection - Array of MetadataObjectAttribute
//             - Array of MetadataObjectTabularSection
//   NamesOnly - Boolean
// Returns:
//   Array
//
Function ItemsList(Collection, NamesOnly = True)
	Result = New Array;
	For Each Item In Collection Do
		If NamesOnly Then
			Result.Add(Item.Name);
		Else
			Result.Add(Item);
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function SetIntersection(Set1, Set2) Export
	
	Result = New Array;
	
	For Each Item In Set2 Do
		IndexOf = Set1.Find(Item);
		If IndexOf <> Undefined Then
			Result.Add(Item);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function AttributesIntersection(AttributesCollection1, AttributesCollection2)
	
	Result = New Array;
	
	For Each Attribute2 In AttributesCollection2 Do
		For Each Attribute1 In AttributesCollection1 Do
			If Attribute1.Name = Attribute2.Name 
				And (Attribute1.Type = Attribute2.Type Or Attribute1.Name = "Ref") Then
				Result.Add(Attribute1);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use.
Function DataCompositionSchema(QueryText) Export
	DataCompositionSchema = New DataCompositionSchema;
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	DataSet.Query = QueryText;
	DataSet.Name = "DataSet1";
	
	Return DataCompositionSchema;
EndFunction

// For internal use.
Function ChangeObjects1(Parameters, ResultAddress) Export
	
	ObjectsToProcess = Parameters.ObjectsToProcess.Get().Rows;
	ObjectsForChanging   = Parameters.ObjectsForChanging.Get().Rows;
	
	ChangeResult = New Structure("HasErrors, ProcessingState");
	ChangeResult.HasErrors         = False;
	ChangeResult.ProcessingState = New Map;
	
	If ObjectsToProcess = Undefined Then
		ObjectsToProcess = New Array;// Array of AnyRef
		For Each ObjectToChange In ObjectsForChanging Do
			ObjectsToProcess.Add(ObjectToChange);
		EndDo;
	EndIf;
	
	If ObjectsToProcess.Count() = 0 Then
		PutToTempStorage(ChangeResult, ResultAddress);
		Return Undefined;
	EndIf;
	
	If Parameters.OperationType = "ExecuteAlgorithm" And DataSeparationEnabled() Then
		PutToTempStorage(ChangeResult, ResultAddress);
		Return Undefined;
	EndIf;
	
	StopChangeOnError = Parameters.StopChangeOnError;
	If StopChangeOnError = Undefined Then
		StopChangeOnError = Parameters.InterruptOnError;
	EndIf;
	
	RunAlgorithmCodeInSafeMode = (Parameters.ExecutionMode <> 1);
	
	Return RunObjectsChangeInMultipleThreads(Parameters, ObjectsToProcess, ChangeResult,
		StopChangeOnError, RunAlgorithmCodeInSafeMode);
	
EndFunction

// Parameters:
//   Block - DataLock 
//   Ref - AnyRef
//
Procedure LockRef(Val Block, Val Ref)
	
	LockDataForEdit(Ref);
	LockItem = Block.Add(Common.ObjectKindByRef(Ref) + "." + Ref.Metadata().Name);
	LockItem.SetValue("Ref", Ref);

EndProcedure

// Returns:
//   Structure:
//   * ObjectAttributesToChange - Array of String 
//   * AdditionalObjectAttributesToChange - Map
//   * AdditionalObjectInfoToChange - Map
//   * AddInfoRecordsArray - Array of InformationRegisterRecordManager.AdditionalInfo
//
Function MakeChanges(Val ObjectData, Val ObjectToChange, Val Parameters)
	
	Result = New Structure;
	Result.Insert("ObjectAttributesToChange",    New Array);
	Result.Insert("AdditionalObjectAttributesToChange", New Map);
	Result.Insert("AdditionalObjectInfoToChange",  New Map);
	Result.Insert("AddInfoRecordsArray",      New Array);
	Result.Insert("ExternalAttributesToChange",    New Map);
	
	AdditionalAttributes = New Array;
	For Each Operation In Parameters.AttributesToChange Do
		If Operation.OperationKind = 2 Then
			AdditionalAttributes.Add(Operation.Property);
		EndIf;
	EndDo;
	
	PropertiesOfAdditionalDetails = Undefined;
	If AdditionalAttributes.Count() > 0 Then
		PropertiesOfAdditionalDetails = Common.ObjectsAttributesValues(AdditionalAttributes, "ValueType, MultilineInputField");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
	EndIf;
	
	// Run modification operations.
	For Each Operation In Parameters.AttributesToChange Do
		
		Value = EvalExpression(Operation.Value, ObjectToChange, Parameters.AvailableAttributes);
		If Operation.OperationKind = 1 Then // Change an attribute.
			
			If ObjectToChange[Operation.Name] = Null Then
				Continue;
			EndIf;
			
			ObjectToChange[Operation.Name] = Value;
			Result.ObjectAttributesToChange.Add(Operation.Name);
			
		ElsIf Operation.OperationKind = 2 Then // Change an additional attribute.
			
			If Not PropertyMustChange(ObjectToChange.Ref, Operation.Property, Parameters) Then
				Continue;
			EndIf;
			
			PropertiesValues = New Map;
			PropertiesValues.Insert(Operation.Property, Value);
			ModulePropertyManager.SetPropertiesForObject(ObjectToChange, PropertiesValues);
			
			FormAttributeName = AddAttributeNamePrefix() + StrReplace(String(Operation.Property.UUID()), "-", "_");
			Result.AdditionalObjectAttributesToChange.Insert(FormAttributeName, Value);
			
		ElsIf Operation.OperationKind = 3 Then // Change an additional information record.
			
			If Not PropertyMustChange(ObjectToChange.Ref, Operation.Property, Parameters) Then
				Continue;
			EndIf;
			
			PropertiesTable = New ValueTable;
			PropertiesTable.Columns.Add("Property");
			PropertiesTable.Columns.Add("Value");
			
			PropertyDetails = PropertiesTable.Add();
			PropertyDetails.Property = Operation.Property;
			PropertyDetails.Value = Value;
			
			ModulePropertyManager.WriteObjectProperties(ObjectToChange.Ref, PropertiesTable);
			
			FormAttributeName = AddInfoNamePrefix() + StrReplace(String(Operation.Property.UUID()), "-", "_");
			Result.AdditionalObjectInfoToChange.Insert(FormAttributeName, Value);
		
		ElsIf Operation.OperationKind = 4 Then // Update an external attribute.
			
			If Value = Undefined
			   And Operation.AllowedTypes.Types().Count() = 1 Then
				
				CastedValue = Operation.AllowedTypes.AdjustValue(Value);
			Else
				CastedValue = Value;
			EndIf;
			Result.ExternalAttributesToChange.Insert(Operation.Name, CastedValue);
			
		EndIf;
		
	EndDo;
	
	If Parameters.TabularSectionsToChange.Count() > 0 Then
		MakeChangesToTabularSections(ObjectToChange, ObjectData, Parameters.TabularSectionsToChange);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RunAlgorithmCode(Val Object, Val AlgorithmCode, Val ExecuteInSafeMode)
	
	If ExecuteInSafeMode Or Not AccessRight("Administration", Metadata) Then
		AlgorithmCode = "Object = Parameters;
		|" + AlgorithmCode;
		Common.ExecuteInSafeMode(AlgorithmCode, Object);
	Else
		Execute AlgorithmCode; // ACC:487 In error correction scenarios, the code can be executed on behalf of an Administrator.
	EndIf;
	
EndProcedure

Function DataSeparationEnabled()
	
	SaaSAvailable = Metadata.FunctionalOptions.Find("SaaSOperations");
	If SaaSAvailable <> Undefined Then
		OptionName1 = "SaaSOperations";
		Return IsSeparatedConfiguration() And GetFunctionalOption(OptionName1);
	EndIf;
	
	Return False;
	
EndFunction

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean
//
Function IsSeparatedConfiguration()
	
	HasSeparators = False;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			HasSeparators = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasSeparators;
	
EndFunction

Function DetermineWriteMode(Val ObjectToChange, Val IsDocument, Val DeveloperMode)
	
	WriteMode = Undefined;
	If DeveloperMode Then
		WriteMode = Undefined;
		ObjectToChange.DataExchange.Load = True;
	ElsIf IsDocument Then
		WriteMode = DocumentWriteMode.Write;
		If ObjectToChange.Posted Then
			WriteMode = DocumentWriteMode.Posting;
		ElsIf ObjectToChange.Metadata().Posting = Metadata.ObjectProperties.Posting.Allow Then
			WriteMode = DocumentWriteMode.UndoPosting;
		EndIf;
	EndIf;
	Return WriteMode;

EndFunction

Function PropertyMustChange(Ref, Property, Parameters)
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		If ModulePropertyManager = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	ObjectKindByRef = Common.ObjectKindByRef(Ref);
	If (ObjectKindByRef = "Catalog" Or ObjectKindByRef = "ChartOfCharacteristicTypes")
		And Common.ObjectIsFolder(Ref) Then
		Return False;
	EndIf;
	
	If Not ModulePropertyManager.CheckObjectProperty(Ref, Property) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function FillCheckErrorsText()
	
	Result = "";
	ArrayOfMessages = GetUserMessages(True);
	
	For Each UserMessage In ArrayOfMessages Do
		Result = Result + UserMessage.Text + Chars.LF;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillChangeResult(Result, Ref, ErrorMessage)
	
	ChangeStatus = New Structure;
	ChangeStatus.Insert("ErrorCode", "Error");
	ChangeStatus.Insert("ErrorMessage", ErrorMessage);
	
	Result.ProcessingState.Insert(Ref, ChangeStatus);
	Result.HasErrors = True;
	
EndProcedure

Procedure FillAdditionalPropertiesChangeResult(Result, Ref, ObjectToChange, Changes = Undefined)
	
	ChangeStatus = New Structure;
	ChangeStatus.Insert("ErrorCode", "");
	ChangeStatus.Insert("ErrorMessage", "");
	ChangeStatus.Insert("ChangedAttributesValues", New Map);
	If Changes <> Undefined Then
		For Each AttributeName In Changes.ObjectAttributesToChange Do
			ChangeStatus.ChangedAttributesValues.Insert(AttributeName, ObjectToChange[AttributeName]);
		EndDo;
	EndIf;
	ChangeStatus.Insert("ChangedAddAttributesValues", 
		?(Changes <> Undefined, Changes.AdditionalObjectAttributesToChange, Changes));
	ChangeStatus.Insert("ChangedAddInfoValues", 
		?(Changes <> Undefined, Changes.AdditionalObjectInfoToChange, Changes));
	
	Result.ProcessingState.Insert(Ref, ChangeStatus);
	
EndProcedure

Function AddAttributeNamePrefix()
	Return "AdditionalAttribute5_";
EndFunction

Function AddInfoNamePrefix()
	Return "AdditionalInfoItem1_";
EndFunction

Procedure MakeChangesToTabularSections(ObjectToChange, ObjectData, ChangesToTabularSections)
	
	For Each TabularSectionChanges In ChangesToTabularSections Do
		TableName = TabularSectionChanges.Key;
		AttributesToChange = TabularSectionChanges.Value;
		For Each TableRow In ObjectToChange[TableName] Do
			If StringMatchesFilter(TableRow, ObjectData, TableName) Then
				For Each AttributeToChange In AttributesToChange Do
					TableRow[AttributeToChange.Name] = AttributeToChange.Value;
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Parameters:
//   TableRow - ValueTableRow:
//    * LineNumber - Number
//   
//   ObjectData - ValueTreeRow
//                 - Structure:
//    * Ref - AnyRef
//    * TabularSections - ValueTree
//   
//   TableName - String
//
Function StringMatchesFilter(TableRow, ObjectData, TableName)
	
	Rows = ?(TypeOf(ObjectData) = Type("ValueTreeRow"), 
		ObjectData.Rows, ObjectData.TabularSections.Rows);
	
	Return Rows.FindRows(New Structure(TableName + "LineNumber", TableRow.LineNumber)).Count() = 1;
	
EndFunction

Procedure FillEditableObjectsCollection(AvailableObjects, ShowHiddenItems) Export

	MetadataObjectsCollections = New Array;
	MetadataObjectsCollections.Add(Metadata.Catalogs);
	MetadataObjectsCollections.Add(Metadata.Documents);
	MetadataObjectsCollections.Add(Metadata.BusinessProcesses);
	MetadataObjectsCollections.Add(Metadata.Tasks);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCalculationTypes);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsCollections.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsCollections.Add(Metadata.ExchangePlans);
	
	PrefixOfObjectsToDelete = "delete";
	ObjectsToDelete = New ValueList;
	ObjectsManagers = ObjectsManagersForEditingAttributes();
	
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each MetadataObject In MetadataObjectCollection Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			
			If Not ShowHiddenItems Then
				If StrStartsWith(Lower(MetadataObject.Name), PrefixOfObjectsToDelete)
					Or IsInternalObject(MetadataObject, ObjectsManagers) Then
					Continue;
				EndIf;
			EndIf;
			
			If AccessRight("Update", MetadataObject) Then
				If StrStartsWith(Lower(MetadataObject.Name), PrefixOfObjectsToDelete) Then
					ObjectsToDelete.Add(MetadataObject.FullName(), MetadataObject.Presentation());
				Else 
					AvailableObjects.Add(MetadataObject.FullName(), MetadataObject.Presentation());
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	AvailableObjects.SortByPresentation();
	ObjectsToDelete.SortByPresentation();
	
	For Each Item In ObjectsToDelete Do
		AvailableObjects.Add(Item.Value, Item.Presentation);
	EndDo;
	
EndProcedure

Function IsInternalObject(Val MetadataObject, Val ObjectsManagers)
	
	AttributesEditingSettings = AttributesEditingSettings(MetadataObject, ObjectsManagers);
	
	ToEdit = AttributesEditingSettings.ToEdit;
	NotToEdit = AttributesEditingSettings.NotToEdit;
	
	If TypeOf(NotToEdit) = Type("Array") And NotToEdit.Find("*") <> Undefined
		Or TypeOf(ToEdit) = Type("Array") And Not ValueIsFilled(ToEdit) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function AttributesEditingSettings(MetadataObject, ObjectsManagers = Null) Export
	
	If ObjectsManagers = Null Then
		ObjectsManagers = ObjectsManagersForEditingAttributes();
	EndIf;
	
	ToEdit   = Undefined;
	NotToEdit = Undefined;
	
	AvailableMethods = ObjectManagerMethodsForEditingAttributes(MetadataObject.FullName(), ObjectsManagers);
	ReadEditable = AvailableMethods.AttributesToEditInBatchProcessing;
	ReadNonEditable = AvailableMethods.AttributesToSkipInBatchProcessing;
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If ReadEditable Then
		ToEdit = ObjectManager.AttributesToEditInBatchProcessing();
	EndIf;
	
	If ReadNonEditable Then
		NotToEdit = ObjectManager.AttributesToSkipInBatchProcessing();
	EndIf;
	
	SSLSubsystemsIntegration.OnDefineEditableObjectAttributes(
		MetadataObject, ToEdit, NotToEdit);
	
	BatchEditObjectsOverridable.OnDefineEditableObjectAttributes(
		MetadataObject, ToEdit, NotToEdit);
	
	Result = New Structure;
	Result.Insert("ToEdit", ToEdit);
	Result.Insert("NotToEdit", NotToEdit);
	
	Return Result;
	
EndFunction

Function ObjectManagerMethodsForEditingAttributes(ObjectName, ObjectsManagers)
	
	AvailableMethods = New Structure;
	AvailableMethods.Insert("AttributesToEditInBatchProcessing", False);
	AvailableMethods.Insert("AttributesToSkipInBatchProcessing", False);

	InformationOnObjectManager = ObjectsManagers[ObjectName];
	
	If InformationOnObjectManager = Undefined Then
		Return AvailableMethods;
	EndIf;
	
	For Each MethodName In StrSplit(InformationOnObjectManager, Chars.LF, False) Do
		If MethodName = "AttributesToEditInBatchProcessing" Then
			AvailableMethods.AttributesToEditInBatchProcessing = True;
		ElsIf MethodName = "AttributesToSkipInBatchProcessing" Then
			AvailableMethods.AttributesToSkipInBatchProcessing = True;
		ElsIf MethodName = "*" Then
			AvailableMethods.AttributesToEditInBatchProcessing = True;
			AvailableMethods.AttributesToSkipInBatchProcessing = True;
		EndIf;
	EndDo;
	
	Return AvailableMethods;
	
EndFunction

Function ObjectsManagersForEditingAttributes()
	
	ObjectsWithLockedAttributes = New Map;
	SSLSubsystemsIntegration.OnDefineObjectsWithEditableAttributes(ObjectsWithLockedAttributes);
	BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes(ObjectsWithLockedAttributes);
	
	Return ObjectsWithLockedAttributes;
	
EndFunction

Function EvalExpression(Val Expression, Object, AvailableAttributes)
	
	If Not(TypeOf(Expression) = Type("String") And StrStartsWith(Expression, "=")) Then
		Return Expression;
	EndIf;
		
	If StrStartsWith(Expression, "'=") Then
		Return Mid(Expression, 2);
	EndIf;
	
	Expression = Mid(Expression, 2);
	
	For Each AttributeDetails In AvailableAttributes Do
		If StrFind(Expression, "[" + AttributeDetails.Presentation + "]") = 0 Then
			Continue;
		EndIf;
		
		Value = "";
		If AttributeDetails.OperationKind = 1 Then
			Value = Object[AttributeDetails.Name];
			
		ElsIf AttributeDetails.OperationKind < 4 Then
			ModulePropertyManager = Common.CommonModule("PropertyManager");
			ListOfProperties = New Array;
			ListOfProperties.Add(AttributeDetails.Property);
			PropertiesValues = ModulePropertyManager.PropertiesValues(Object.Ref, True, True, ListOfProperties);
			For Each TableRow In PropertiesValues.FindRows(New Structure("Property", AttributeDetails.Property)) Do
				Value = TableRow.Value;
			EndDo;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mục tin ""%1"" không được hỗ trợ trong các biểu thức';
					|ru = 'Реквизит ""%1"" не поддерживается в выражениях';
					|en = 'Expressions do not support the ""%1"" attribute'; fa = 'Expressions do not support the ""%1"" attribute';
					|it = 'Реквизит ""%1"" не поддерживается в выражениях';
					|pl = 'Expressions do not support the ""%1"" attribute';
					|tr = '""%1"" özelliği ifadelerde desteklenmiyor'"), AttributeDetails.Presentation);
			Raise ErrorText;
		EndIf;
		
		Expression = StrReplace(Expression, "[" + AttributeDetails.Presentation + "]", """" 
			+ StrReplace(StrReplace(Value, """", """"""), Chars.LF, Chars.LF + "|") + """");
	EndDo;
	
	Return Common.CalculateInSafeMode(Expression);
	
EndFunction

Procedure DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1 = True)
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1);
	EndIf;
	
EndProcedure

#Region MultiThreadedObjectModification

// ACC:581-off - An export function as it's called from a background job.
Function ObjectsBatchChangeResult(ObjectsToProcess, ChangeResult, ModificationSettings) Export

	Ref         = Undefined;
	WriteError = True;
	
	DisableAccessKeysUpdate(True);
	If ModificationSettings.ChangeInTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		If ModificationSettings.ChangeInTransaction Then
			Block = New DataLock;
			For Each ObjectData In ObjectsToProcess Do
				Ref = ObjectData.Ref;
				LockRef(Block, ObjectData.Ref);
			EndDo;
			Block.Lock();
		EndIf;
		
		For Each ObjectData In ObjectsToProcess Do
			
			WriteError = True;
			BeginTransaction();
			Try
				
				Ref = ObjectData.Ref;
				If Not ModificationSettings.ChangeInTransaction Then
					Block = New DataLock;
					LockRef(Block, Ref);
					Block.Lock();
				EndIf;
				
				ObjectToChange = Ref.GetObject();
				
				Changes = Undefined;
				If ModificationSettings.OperationType = "ExecuteAlgorithm" Then
					RunAlgorithmCode(ObjectToChange, ModificationSettings.AlgorithmCode,
						ModificationSettings.RunAlgorithmCodeInSafeMode);
				Else
					Changes = MakeChanges(ObjectData, ObjectToChange, ModificationSettings);
				EndIf;
				
				// Write mode.
				IsDocument = Metadata.Documents.Contains(ObjectToChange.Metadata());
				WriteMode = DetermineWriteMode(ObjectToChange, IsDocument, ModificationSettings.DeveloperMode);
				
				// Validate value population.
				If Not ModificationSettings.DeveloperMode Then
					If Not IsDocument Or WriteMode = DocumentWriteMode.Posting Then
						If Not ObjectToChange.CheckFilling() Then
							Raise FillCheckErrorsText();
						EndIf;
					EndIf;
				EndIf;
				
				// Write additional info.
				If Changes <> Undefined And Changes.AddInfoRecordsArray.Count() > 0 Then
					For Each RecordManager In Changes.AddInfoRecordsArray Do
						RecordManager.Write(True);
					EndDo;
				EndIf;
				
				If Changes <> Undefined And ValueIsFilled(Changes.ExternalAttributesToChange) Then
					UsersInternal.OnChangeExternalAttributes(ObjectToChange,
						Changes.ExternalAttributesToChange);
				EndIf;
				
				ChangesAreConfigured = ValueIsFilled(ModificationSettings.AttributesToChange)
					Or ValueIsFilled(ModificationSettings.TabularSectionsToChange);
				
				MustWriteObject = ModificationSettings.ObjectWriteOption <> "NotWrite"
					And (ObjectToChange.Modified() Or Not ChangesAreConfigured);
				
				// Write the object.
				If MustWriteObject Then
					If WriteMode <> Undefined Then
						ObjectToChange.Write(WriteMode);
					Else
						ObjectToChange.Write();
					EndIf;
				EndIf;
				
				FillAdditionalPropertiesChangeResult(ChangeResult, Ref, ObjectToChange, Changes);
				
				UnlockDataForEdit(Ref);
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				If ModificationSettings.ChangeInTransaction Then
					UnlockDataForEdit(Ref);
				EndIf;
				
				FillChangeResult(ChangeResult, Ref, ErrorInfo());
				If ModificationSettings.StopChangeOnError Or ModificationSettings.ChangeInTransaction Then
					WriteError = False;
					Raise;
				EndIf;
				
				Continue;
			EndTry;
			
		EndDo;
		
		DisableAccessKeysUpdate(False);
		If ModificationSettings.ChangeInTransaction Then
			CommitTransaction();
		EndIf;
		
	Except
		
		If ModificationSettings.ChangeInTransaction Then 
			RollbackTransaction();
			For Each ObjectData In ObjectsToProcess Do
				UnlockDataForEdit(ObjectData.Ref);
			EndDo;
		EndIf;
		
		DisableAccessKeysUpdate(False, ModificationSettings.ChangeInTransaction);
		
		If WriteError Then
			BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			FillChangeResult(ChangeResult, Ref, BriefErrorDescription);
		EndIf;
		
	EndTry;
	
	Return ChangeResult;
	
EndFunction
// ACC:581-on

Function RunObjectsChangeInMultipleThreads(Parameters, ObjectsToProcess, ChangeResult,
		StopChangeOnError, RunAlgorithmCodeInSafeMode)
	
	FormIdentifier = New UUID;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thay đổi mục tin theo nhóm';
														|ru = 'Групповое изменение реквизитов';
														|en = 'Bulk attribute edit'; fa = 'ویرایش گروهی ویژگی‌ها';
														|it = 'Modifica di gruppo dei requisiti';
														|pl = 'Zmiana grupowa atrybutów';
														|tr = 'Toplu öznitelik düzenleme'");
	
	BatchesArray    = New Array;
	PortionOfObjects  = New Array;
	ObjectsCounter = 0;
	
	LongRunningOperationsThreadCount = TimeConsumingOperations.AllowedNumberofThreads();
	
	ShouldProcessInSingleThread = Parameters.ChangeInTransaction Or Parameters.InterruptOnError; 
	If LongRunningOperationsThreadCount > 0 And Not ShouldProcessInSingleThread Then
		ObjectCountInBatch = Int(ObjectsToProcess.Count() / LongRunningOperationsThreadCount);
	Else
		ObjectCountInBatch = ObjectsToProcess.Count();
	EndIf;
	
	TabularSectionsDetails = TabularSectionsDetails(Parameters);
	
	For Each ObjectData In ObjectsToProcess Do
		If ObjectsCounter = ObjectCountInBatch Then
			BatchesArray.Add(PortionOfObjects);
			PortionOfObjects  = New Array;
			ObjectsCounter = 0;
		EndIf;
		
		TabularSections = TabularSectionsDetails.Copy();
		
		AddValueTreeRowsRecursively(TabularSections, ObjectData);
		
		DataOfBatch = New Structure;
		DataOfBatch.Insert("Ref",         ObjectData.Ref);
		DataOfBatch.Insert("TabularSections", TabularSections);
		PortionOfObjects.Add(DataOfBatch);
		
		ObjectsCounter = ObjectsCounter + 1;
	EndDo;
	
	If PortionOfObjects.Count() > 0 Then
		BatchesArray.Add(PortionOfObjects);
	EndIf;
	
	MethodParameters      = New Map;
	BatchesUpperBound = BatchesArray.UBound();
	
	ModificationSettings = ModificationSettings(Parameters, RunAlgorithmCodeInSafeMode);
	
	For BatchIndex = 0 To BatchesUpperBound Do
		ParametersArray = New Array;
		ParametersArray.Add(BatchesArray[BatchIndex]);
		ParametersArray.Add(ChangeResult);
		ParametersArray.Add(ModificationSettings);
		
		MethodParameters.Insert(BatchIndex, ParametersArray);
	EndDo;
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunctionInMultipleThreads(
		"DataProcessor.BatchEditAttributes.ObjectModule.ObjectsBatchChangeResult",
		ExecutionParameters,
		MethodParameters);
		
	Return ExecutionResult;
	
EndFunction

Function TabularSectionsDetails(Parameters)

	TabularSectionsDetails = New ValueTree;
	
	ObjectsForChanging = Parameters.ObjectsForChanging.Get();
	If ObjectsForChanging = Undefined Then
		ObjectsForChanging = Parameters.ObjectsToProcess.Get();
	EndIf;
	
	For Each Column In ObjectsForChanging.Columns Do
		TabularSectionsDetails.Columns.Add(Column.Name, Column.ValueType, Column.Title, Column.Width);
	EndDo;
	
	Return TabularSectionsDetails;
	
EndFunction

Procedure AddValueTreeRowsRecursively(Recipient, Source)
	
	For Each SourceRow1 In Source.Rows Do
		
		CurrentRow = Recipient.Rows.Add();
		FillPropertyValues(CurrentRow, SourceRow1);
		
		If SourceRow1.Rows.Count() > 0 Then
			AddValueTreeRowsRecursively(CurrentRow, SourceRow1);
		EndIf;
		
	EndDo;
	
EndProcedure

Function ModificationSettings(Parameters, RunAlgorithmCodeInSafeMode)
	
	ModificationSettings = New Structure;
	ModificationSettings.Insert("ObjectWriteOption");
	ModificationSettings.Insert("RunAlgorithmCodeInSafeMode", RunAlgorithmCodeInSafeMode);
	ModificationSettings.Insert("AvailableAttributes");
	ModificationSettings.Insert("AttributesToChange");
	ModificationSettings.Insert("TabularSectionsToChange");
	ModificationSettings.Insert("ChangeInTransaction");
	ModificationSettings.Insert("AlgorithmCode");
	ModificationSettings.Insert("StopChangeOnError");
	ModificationSettings.Insert("DeveloperMode");
	ModificationSettings.Insert("OperationType");
	
	FillPropertyValues(ModificationSettings, Parameters);
	
	Return ModificationSettings;
	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ObjectsBatchChangeResult", True);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf