#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AbbreviatedNameOfConfiguration = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.RulesForIntegrationObjectPresentationIS.Title
			= StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng %1';
					|ru = 'Объект %1';
					|en = 'Object %1'; fa = 'Object %1';
					|it = 'Oggetto %1';
					|pl = 'Obiekt %1';
					|tr = 'Nesne %1'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
	FillInTree();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ObjectCount < 12 Then
		For Each Item In ObjectsTree.GetItems() Do
			Items.ObjectsTree.Expand(Item.GetID());
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_RuleChanged"
			Or EventName = "IntegrationWith1CDocumentManagement_RuleCreated" Then
		FillInEnabledAttributeInTree();
		SetCommandsAvailability(Items.ObjectsTree.CurrentData);
		SetSelectionOfIntegrationRules(Items.ObjectsTree.CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectsTree

&AtClient
Procedure ObjectsTreeOnActivateRow(Item)
	
	SetCommandsAvailability(Items.ObjectsTree.CurrentData);
	SetSelectionOfIntegrationRules(Items.ObjectsTree.CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRulesForIntegration

&AtClient
Procedure RulesForIntegrationBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeIS", CurrentData.ObjectTypeName);
	If Copy Then
		FormParameters.Insert("CopyingValue", Items.RulesForIntegration.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ItemForm",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure RulesForIntegrationOnChange(Item)
	
	FillInEnabledAttributeInTree();
	SetCommandsAvailability(Items.ObjectsTree.CurrentData);
	SetSelectionOfIntegrationRules(Items.ObjectsTree.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Customize(Command)
	
	If Items.ObjectsTree.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData.Enable Then
		Return;
	EndIf;
	If CurrentData.AutoTune Then
		SetItUpAutomatically(CurrentData);
	Else
		ConfigureManually(CurrentData);
	EndIf;
	
EndProcedure
	
&AtClient
Procedure SwitchShowRemoteIntegrationRules(Command)
	
	ShowDeleted = Not ShowDeleted;
	Items.ShowDeletedIntegrationRules.Check = ShowDeleted;
	SetSelectionOfIntegrationRules(Items.ObjectsTree.CurrentData);
	
EndProcedure

#EndRegion

#Region Private

// Fills in the tree and puts the Enabled attribute in it.
&AtServer
Procedure FillInTree()
	
	ObjectCount = FillTreeWithMetadata();
	FillInEnabledAttributeInTree();
	
EndProcedure

// Fills the tree with objects and subsystems according to metadata.
//
&AtServer
Function FillTreeWithMetadata()
	
	Tree = FormAttributeToValue("ObjectsTree");
	Tree.Rows.Clear();
	
	// We convert the description of the types of the command parameter into an array of metadata objects.
	Types = IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	MetadataObjects = New ValueList;
	For Each Type In Types Do
		MetadataObject = Metadata.FindByType(Type);
		MetadataObjects.Add(MetadataObject, MetadataObject.Presentation());
	EndDo;
	MetadataObjects.SortByPresentation();
	
	ObjectsWithAutomaticConfiguration = New ValueTable;
	ObjectsWithAutomaticConfiguration.Columns.Add("ObjectTypeName");
	ObjectsWithAutomaticConfiguration.Columns.Add("DescriptionOfActionsPerformed");
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDefiningObjectsThatSupportAutoTuning(ObjectsWithAutomaticConfiguration);
	
	ProcessSubsystems(
		Metadata.Subsystems,
		Tree.Rows,
		MetadataObjects,
		ObjectsWithAutomaticConfiguration,
		NULL,
		True);
	
	ValueToFormAttribute(Tree, "ObjectsTree");
	
	Return MetadataObjects.Count();
	
EndFunction

// Recursively adds subsystems from the passed collection if they contain the specified
// metadata objects, and returns True if at least one is added.
//
&AtServer
Function ProcessSubsystems(Subsystems, TreeRows, MetadataObjects, ObjectsWithAutomaticConfiguration,
		AutoTune, OnlyIncludedInCommandInterface = False)
	
	Result = False;
	
	For Each Subsystem In Subsystems Do
		
		If StrStartsWith(Subsystem.Name, "Delete") Then
			Continue;
		EndIf;
		
		Cancel = False;
		If OnlyIncludedInCommandInterface And Not Subsystem.IncludeInCommandInterface Then
			Cancel = True;
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreOverridable.WhenAddingSubsystemToTreeOfIntegrableObjects(
			Subsystem,
			Cancel);
		
		If Cancel Then
			Continue;
		EndIf;
		
		SubsystemRow = TreeRows.Add();
		SubsystemRow.SubsystemName = Subsystem.Name;
		SubsystemRow.PresentationOfSubsystem = Subsystem.Presentation();
		SubsystemRow.IsFolder = True;
		SubsystemRow.AutoTune = NULL;
		
		SubsystemLines = SubsystemRow.Rows;
		
		SubsystemIsNeeded = ProcessSubsystems(
			Subsystem.Subsystems,
			SubsystemLines,
			MetadataObjects,
			ObjectsWithAutomaticConfiguration,
			SubsystemRow.AutoTune);
		
		For Each MetadataObject In MetadataObjects Do
			
			If StrStartsWith(MetadataObject.Value.Name, "Delete") Then
				Continue;
			EndIf;
			
			If Subsystem.Content.Contains(MetadataObject.Value) Then
				
				SubsystemIsNeeded = True;
				ObjectString = SubsystemLines.Add();
				ObjectString.ObjectTypeName = MetadataObject.Value.FullName();
				ObjectString.ObjectPresentation = MetadataObject.Value.Presentation();
				AutoTuneLine = ObjectsWithAutomaticConfiguration.Find(ObjectString.ObjectTypeName, "ObjectTypeName");
				
				If AutoTuneLine <> Undefined Then
					ObjectString.AutoTune = True;
					ObjectString.ToolTip = AutoTuneLine.DescriptionOfActionsPerformed;
				Else
					ObjectString.AutoTune = False;
				EndIf;
				
				If SubsystemRow.AutoTune = NULL Then
					SubsystemRow.AutoTune = ObjectString.AutoTune;
				ElsIf TypeOf(SubsystemRow.AutoTune) = Type("Boolean")
						And SubsystemRow.AutoTune <> ObjectString.AutoTune Then
					SubsystemRow.AutoTune = Undefined;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If SubsystemIsNeeded Then
			Result = True;
			If AutoTune = NULL Then
				AutoTune = SubsystemRow.AutoTune;
			ElsIf TypeOf(AutoTune) = Type("Boolean") And AutoTune <> SubsystemRow.AutoTune Then
				AutoTune = Undefined;
			EndIf;
		Else
			TreeRows.Delete(SubsystemRow);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in the Enabled attribute in the tree according to the existence of suitable rules in the IB.
//
&AtServer
Procedure FillInEnabledAttributeInTree()
	
	Query = New Query(
		"SELECT DISTINCT
		|	Rules.ObjectTypeIS AS ObjectTypeIS
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	NOT Rules.DeletionMark
		|	AND Rules.ObjectTypeDM <> """"");
	ObjectsTypes = Query.Execute().Unload().UnloadColumn("ObjectTypeIS");
	
	ProcessTreeRows(ObjectsTree.GetItems(), ObjectsTypes);
	
EndProcedure

// Recursively processes tree rows, setting the Enabled attribute according to the passed array
// of objects for which integration rules are found.
//
&AtServer
Procedure ProcessTreeRows(TreeRows, ObjectsTypes)
	
	For Each TreeRow In TreeRows Do
		
		If TreeRow.IsFolder Then
			
			ProcessTreeRows(TreeRow.GetItems(), ObjectsTypes);
			
		Else
			
			TreeRow.Enable =
				(ObjectsTypes.Find(TreeRow.ObjectTypeName) <> Undefined);
				
			If TreeRow.Enable Then
				TreeRow.Picture = PictureLib.IntegrationEnabled;
			ElsIf TreeRow.AutoTune Then
				TreeRow.Picture = PictureLib.ConfigureIntegrationAutomatically;
			Else
				TreeRow.Picture = Undefined;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets the availability of commands depending on the active row of the tree.
//
&AtClient
Procedure SetCommandsAvailability(CurrentData)
	
	Items.ContextSetUpAutomatically.Enabled = False;
	Items.ManuallyConfigureContext.Enabled = False;
	Items.Customize.Enabled = False;
	
	If CurrentData = Undefined Then
		Items.PagesAutomaticManualSetting.CurrentPage
			= Items.BlankPage;
	
	ElsIf CurrentData.IsFolder Then
		Items.PagesAutomaticManualSetting.CurrentPage
			= Items.PageSubsystem;
		If CurrentData.AutoTune = True Then
			ToolTip = NStr("vi = 'Các đối tượng của phân hệ hỗ trợ tự động tùy chỉnh tích hợp.';
							|ru = 'Объекты подсистемы поддерживают автоматическую настройку интеграции.';
							|en = 'Subsystem objects support automatic integration configuration. '; fa = 'Subsystem objects support automatic integration configuration. ';
							|it = 'Gli oggetti di sottosistema supportano l''impostazione automatica di integrazione.';
							|pl = 'Obiekty podsystemu obsługują automatyczne ustawienie integracji.';
							|tr = 'Alt sistem nesneleri, otomatik entegrasyon ayarlarını destekler.'");
		ElsIf CurrentData.AutoTune = False Then
			ToolTip = NStr("vi = 'Tùy chỉnh thủ công tích hợp theo các đối tượng trong phân hệ.';
							|ru = 'Интеграция по объектам подсистемы настраивается вручную.';
							|en = 'Integration for subsystem objects is configured manually.'; fa = 'Integration for subsystem objects is configured manually.';
							|it = 'L''integrazione per oggetti di sottosistemi viene impostata manualmente.';
							|pl = 'Integracja według obiektów podsystemu jest ustawiane ręcznie.';
							|tr = 'Alt sistem nesneleri ile entegrasyon manuel olarak ayarlanır.'");
		Else
			ToolTip = NStr("vi = 'Nhiều đối tượng của phân hệ hỗ trợ tự động tùy chỉnh tích hợp.';
							|ru = 'Некоторые объекты подсистемы поддерживают автоматическую настройку интеграции.';
							|en = 'Some subsystem objects support automatic integration configuration.'; fa = 'Some subsystem objects support automatic integration configuration.';
							|it = 'Alcuni oggetti di sottosistema supportano l''impostazione automatica di integrazione.';
							|pl = 'Niektóre obiekty podsystemu obsługują automatyczne ustawienie integracji.';
							|tr = 'Bazı alt sistem nesneleri, otomatik entegrasyon ayarlarını destekler.'");
		EndIf;
	
	ElsIf CurrentData.Enable Then
		Items.PagesAutomaticManualSetting.CurrentPage
			= Items.IntegrationPageIsConfigured;
	
	Else
		Items.Customize.Enabled = True;
		If CurrentData.AutoTune = True Then
			Items.PagesAutomaticManualSetting.CurrentPage
				= Items.ConfigureAutomaticallyPage;
			Items.ContextSetUpAutomatically.Enabled = True;
			If ValueIsFilled(CurrentData.ToolTip) Then
				ToolTip = CurrentData.ToolTip;
			Else
				ToolTip = DescriptionOfDefaultActions();
			EndIf;
		
		Else // Manually.
			Items.PagesAutomaticManualSetting.CurrentPage
				= Items.ManualSetupPage;
			Items.ManuallyConfigureContext.Enabled = True;
		
		EndIf;
	
	EndIf;
	
EndProcedure

// Sets the parameters for selecting a dynamic list of integration rules.
//
&AtClient
Procedure SetSelectionOfIntegrationRules(CurrentData)
	
	If CurrentData = Undefined
		Or CurrentData.IsFolder Then
		
		CommonClientServer.SetDynamicListParameter(RulesForIntegration,
			"ObjectTypeIS",
			Undefined,
			True);
			
	Else
			
		CommonClientServer.SetDynamicListParameter(RulesForIntegration,
			"ObjectTypeIS",
			CurrentData.ObjectTypeName,
			True);
			
	EndIf;
	
	If ShowDeleted Then
		CommonClientServer.SetDynamicListFilterItem(RulesForIntegration,
			"DeletionMark", False,,,False);
	Else
		CommonClientServer.SetDynamicListFilterItem(RulesForIntegration,
			"DeletionMark", False,,,True);
	EndIf;
	
EndProcedure

&AtClient
Function DescriptionOfDefaultActions()
	
	Return NStr("vi = 'Sẽ tự động tạo quy tắc tích hợp.
		|Trong 1C:Document Management sẽ tạo dạng văn bản tương ứng.';
		|ru = 'Будет автоматически создано правило интеграции.
		|В 1С:Документообороте будет создан соответствующий вид документа.';
		|en = 'Integration rule will be created automatically. 
		|Relevant document kind will be created in 1C:Document Management.'; fa = 'Integration rule will be created automatically. 
		|Relevant document kind will be created in 1C:Document Management.';
		|it = 'Sarà creata automaticamente la regola di integrazione.
		|In 1C:Document Management sarà creato il tipo corrispondente di documento.';
		|pl = 'Automatycznie zostanie utworzona reguła integracji.
		|W 1C:Obrót dokumentów zostanie utworzony odpowiedni rodzaj dokumentów.';
		|tr = 'Entegrasyon kuralı otomatik olarak oluşturulacaktır.
		|1C:Document Management''ta ilgili bir belge türü oluşturulacaktır.'");
	
EndFunction

&AtClient
Async Procedure SetItUpAutomatically(Val CurrentData)
	
	ObjectTypeName = CurrentData.ObjectTypeName;
	DescriptionOfActionsPerformed = CurrentData.ToolTip;
	If Not ValueIsFilled(DescriptionOfActionsPerformed) Then
		DescriptionOfActionsPerformed = DescriptionOfDefaultActions();
	EndIf;
	
	QueryText = DescriptionOfActionsPerformed
		+ ?(StrEndsWith(DescriptionOfActionsPerformed, "."), "", ".")
		+ Chars.LF
		+ NStr("vi = 'Tiếp tục?';
				|ru = 'Продолжить?';
				|en = 'Continue?'; fa = 'Continue?';
				|it = 'Continuare?';
				|pl = 'Kontynuować?';
				|tr = 'Devam et?'");
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(QueryText);
	
	If Response = DialogReturnCode.Yes Then
		IntegrationWith1CDocumentManagementClient.StartAutomaticIntegrationConfiguration(ObjectTypeName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureManually(CurrentData)
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeIS", CurrentData.ObjectTypeName);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ItemForm",
		FormParameters,
		ThisObject);
	
EndProcedure

#EndRegion