#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object = Metadata.FindByFullName(Parameters.ObjectType);
	If Object <> Undefined Then
		Synonym = ?(Object.Synonym = "", Object.Name, Object.Synonym);
	Else
		Synonym = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	EndIf;
	
	If Parameters.ThisIsTable Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chọn bảng %1';
				|ru = 'Выбор таблицы %1';
				|en = 'Select table %1'; fa = 'Select table %1';
				|it = 'Selezione tabella %1';
				|pl = 'Wybór tabeli %1';
				|tr = '%1 tablo seçimi'"), Synonym);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chọn mục tin %1';
				|ru = 'Выбор реквизита %1';
				|en = 'Select attribute %1'; fa = 'Select attribute %1';
				|it = 'Selezione attributo %1';
				|pl = 'Wybór atrybutu %1';
				|tr = '%1 öznitelik seçimi'"), Synonym);
	EndIf;
	
	FIllAttributeTree(Parameters.ObjectType,
		Parameters.AttributeNameObjectIS,
		Parameters.ObjectAttributePresentationDM,
		Parameters.ThisIsTable,
		Parameters.Table);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributeTree

&AtClient
Procedure AttributeTreeBeforeExpand(Item, String, Cancel)
	
	RowData = AttributeTree.FindByID(String);
	
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If Not RowData.DetailsRead Then
		FillInSubordinateDetails(String, RowData.NameOfMetadataObjects);
		RowData.DetailsRead = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributeTreeValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	ChooseValueOfAttribute();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ChooseValueOfAttribute();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChooseValueOfAttribute()
	
	CurrentData = Items.AttributeTree.CurrentData;
	If CurrentData = Undefined
		Or CurrentData.Name = ""
		Or CurrentData.Unavailable Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Name", CurrentData.Path);
	Result.Insert("Presentation", CurrentData.PathPresentation);
	Result.Insert("IsAdditionalAttributeIS", CurrentData.IsAdditionalAttributeIS);
	Result.Insert("AdditionalAttributeIS", CurrentData.AdditionalAttributeIS);
	Result.Insert("ThisIsTable", CurrentData.ThisIsTable);
	Result.Insert("Table", CurrentData.Table);
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure FIllAttributeTree(NameOfMetadataObjects, AttributeNameObjectIS, ObjectAttributePresentationDM,
		ThisIsTable, Table)
	
	Tree = FormAttributeToValue("AttributeTree");
	Object = Metadata.FindByFullName(NameOfMetadataObjects);
	
	If Object = Undefined Then
		Return;
	EndIf;
	
	If Not ThisIsTable Then
		
		For Each Attribute In Object.StandardAttributes Do
			
			If Attribute.Name = "Posted" Or Attribute.Name = "Ref" Then
				Continue;
			EndIf;
			
			Presentation = Attribute.Presentation();
			
			NewRow = Tree.Rows.Add();
			NewRow.Name = Attribute.Name;
			NewRow.Path = Attribute.Name;
			NewRow.Presentation = Presentation;
			NewRow.PathPresentation = Presentation;
			NewRow.Type = Attribute.Type;
			
			Types = Attribute.Type.Types();
			If Types.Count() > 1 Then
				Continue;
			EndIf;
			
			AttributeObject = Metadata.FindByType(Types[0]);
			If AttributeObject = Undefined Then
				Continue;
			EndIf;
			NewRow.NameOfMetadataObjects = AttributeObject.FullName();
			
			If Metadata.Catalogs.Contains(AttributeObject)
					Or Metadata.Documents.Contains(AttributeObject)
					Or Metadata.BusinessProcesses.Contains(AttributeObject)
					Or Metadata.Tasks.Contains(AttributeObject)
					Or Metadata.ChartsOfCharacteristicTypes.Contains(AttributeObject)
					Or Metadata.ChartsOfAccounts.Contains(AttributeObject) Then
				
				NewRow.ThereAreAttributes = True;
				NewRow.Rows.Add();
				
			EndIf;
			
		EndDo;
		
		NewRow = Tree.Rows.Add();
		NewRow.Name = "Presentation";
		NewRow.Path = "Presentation";
		NewRow.Presentation = NStr("vi = 'Trình bày';
									|ru = 'Представление';
									|en = 'Presentation'; fa = 'نمایش';
									|it = 'Visualizzazione';
									|pl = 'Presentation';
									|tr = 'Sunum'");
		NewRow.PathPresentation = NStr("vi = 'Trình bày';
										|ru = 'Представление';
										|en = 'Presentation'; fa = 'نمایش';
										|it = 'Visualizzazione';
										|pl = 'Presentation';
										|tr = 'Sunum'");
		NewRow.Type = "String";
		
		For Each Attribute In Object.Attributes Do
			
			If StrStartsWith(Attribute.Name, "Delete") Then
				Continue;
			EndIf;
		
			Presentation = Attribute.Presentation();
			
			NewRow = Tree.Rows.Add();
			NewRow.Name = Attribute.Name;
			NewRow.Path = Attribute.Name;
			NewRow.Presentation = Presentation;
			NewRow.PathPresentation = Presentation;
			NewRow.Type = Attribute.Type;
			
			Types = Attribute.Type.Types();
			If Types.Count() > 1 Then
				Continue;
			EndIf;
			
			AttributeObject = Metadata.FindByType(Types[0]);
			If AttributeObject = Undefined Then
				Continue;
			EndIf;
			NewRow.NameOfMetadataObjects = AttributeObject.FullName();
			
			If Metadata.Catalogs.Contains(AttributeObject)
					Or Metadata.Documents.Contains(AttributeObject)
					Or Metadata.BusinessProcesses.Contains(AttributeObject)
					Or Metadata.Tasks.Contains(AttributeObject)
					Or Metadata.ChartsOfCharacteristicTypes.Contains(AttributeObject)
					Or Metadata.ChartsOfAccounts.Contains(AttributeObject) Then
				
				NewRow.ThereAreAttributes = True;
				NewRow.Rows.Add();
				
			EndIf;
			
		EndDo;
		
		If Metadata.FunctionalOptions.Find("UseAdditionalAttributesAndInfo") <> Undefined
				And GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
			
			TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(NameOfMetadataObjects);
			PropertiesOwner = New(Type(TypeName));
			
			If PropertyManager.UseAddlAttributes(PropertiesOwner) Then
				
				SetOfAdditionalBankingDetails = PropertyManager.ObjectProperties(PropertiesOwner, True, False);
				PropertiesOfAdditionalBankingDetails = Common.ObjectsAttributesValues(
					SetOfAdditionalBankingDetails,
					"Description, ValueType");
				
				For Each AdditionalAttribute5 In SetOfAdditionalBankingDetails Do
					PropertiesOfAdditionalProps = PropertiesOfAdditionalBankingDetails[AdditionalAttribute5];
					If Not ValueIsFilled(AdditionalAttribute5) Or Not ValueIsFilled(PropertiesOfAdditionalProps) Then
						Continue;
					EndIf;
					
					NewRow = Tree.Rows.Add();
					NewRow.Name = PropertiesOfAdditionalProps.Description;
					NewRow.Path = PropertiesOfAdditionalProps.Description;
					NewRow.Presentation = PropertiesOfAdditionalProps.Description;
					NewRow.PathPresentation = PropertiesOfAdditionalProps.Description;
					NewRow.Type = PropertiesOfAdditionalProps.ValueType;
					NewRow.IsAdditionalAttributeIS = True;
					NewRow.AdditionalAttributeIS = AdditionalAttribute5;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ThisIsTable Or ValueIsFilled(Table) Then
		
		For Each TabularSection In Object.TabularSections Do
			
			TreeRows = Tree.Rows;
			
			If StrStartsWith(TabularSection.Name, "Delete") Then
				Continue;
			EndIf;
			
			If ThisIsTable Then
				
				NewRow = TreeRows.Add();
				NewRow.Name = TabularSection.Name;
				NewRow.Path = TabularSection.Name;
				NewRow.Presentation = ?(ValueIsFilled(TabularSection.Synonym),
					TabularSection.Synonym,
					TabularSection.Name);
				NewRow.PathPresentation = NewRow.Presentation;
				NewRow.Type = NStr("vi = 'Bảng';
									|ru = 'Таблица';
									|en = 'Table'; fa = 'جدول';
									|it = 'Tabella';
									|pl = 'Table';
									|tr = 'Tablo'");
				NewRow.ThisIsTable = True;
				
			Else
				
				NewRow = TreeRows.Add();
				NewRow.Name = TabularSection.Name;
				NewRow.Path = TabularSection.Name;
				NewRow.Presentation = ?(ValueIsFilled(TabularSection.Synonym),
					TabularSection.Synonym,
					TabularSection.Name);
				NewRow.PathPresentation = NewRow.Presentation;
				NewRow.Type = NStr("vi = 'Bảng';
									|ru = 'Таблица';
									|en = 'Table'; fa = 'جدول';
									|it = 'Tabella';
									|pl = 'Table';
									|tr = 'Tablo'");
				NewRow.ThisIsTable = True;
				NewRow.Unavailable = True;
				NewRow.Highlighted = (Table = TabularSection.Name);
				NewRow.DetailsRead = True;
				
				TreeRows = NewRow.Rows;
				
				For Each Attribute In TabularSection.Attributes Do
					
					If StrStartsWith(Attribute.Name, "Delete") Then
						Continue;
					EndIf;
				
					Presentation = Attribute.Presentation();
					
					NewRow = TreeRows.Add();
					NewRow.Name = Attribute.Name;
					NewRow.Path = TabularSection.Name + "." + Attribute.Name;
					NewRow.Presentation = Presentation;
					NewRow.PathPresentation = Presentation;
					NewRow.Type = Attribute.Type;
					NewRow.Table = TabularSection.Name;
					NewRow.Unavailable = (Table <> TabularSection.Name);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Tree.Rows.Sort("Presentation");
	
	ValueToFormAttribute(Tree, "AttributeTree");
	
	// Find the table
	If ValueIsFilled(Table) Then
		For Each TreeItem In AttributeTree.GetItems() Do
			If TreeItem.ThisIsTable
				And TreeItem.Name = Table Then
				Items.AttributeTree.CurrentRow = TreeItem.GetID();
			EndIf;
		EndDo;
	EndIf;
	
	// Find the previously selected item.
	If ValueIsFilled(AttributeNameObjectIS) Then
		For Each TreeItem In AttributeTree.GetItems() Do
			If TreeItem.Name = AttributeNameObjectIS
				And TreeItem.Table = Table Then
				Items.AttributeTree.CurrentRow = TreeItem.GetID();
				Return;
			EndIf;
			If TreeItem.ThisIsTable Then
				For Each SubordinateItem In TreeItem.GetItems() Do
					If StrTemplate("%1.%2", SubordinateItem.Table, SubordinateItem.Name) = AttributeNameObjectIS Then
						Items.AttributeTree.CurrentRow = SubordinateItem.GetID();
						Return;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// We will find a suitable one according to the presentation.
	For Each TreeItem In AttributeTree.GetItems() Do
		If TreeItem.Presentation = ObjectAttributePresentationDM
				And TreeItem.Table = Table Then
			Items.AttributeTree.CurrentRow = TreeItem.GetID();
			Return;
		EndIf;
		If TreeItem.ThisIsTable Then
			For Each SubordinateItem In TreeItem.GetItems() Do
				If SubordinateItem.Presentation = ObjectAttributePresentationDM
						And SubordinateItem.Table = Table Then
					Items.AttributeTree.CurrentRow = SubordinateItem.GetID();
					Return;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInSubordinateDetails(String, NameOfMetadataObjects)
	
	RowData = AttributeTree.FindByID(String);
	Object = Metadata.FindByFullName(NameOfMetadataObjects);
	
	If Object = Undefined Then
		Return;
	EndIf;
	
	TreeItems = RowData.GetItems();
	TreeItems.Clear();
	
	For Each Attribute In Object.StandardAttributes Do
		
		If Attribute.Name = "Posted" Or Attribute.Name = "Ref" Then
			Continue;
		EndIf;
		
		Presentation = Attribute.Presentation();
		
		NewRow = TreeItems.Add();
		NewRow.Name = Attribute.Name;
		NewRow.Path = RowData.Path + "." + Attribute.Name;
		NewRow.Presentation = Presentation;
		NewRow.PathPresentation = RowData.PathPresentation + "." + Presentation;
		NewRow.Type = Attribute.Type;
		
		Types = Attribute.Type.Types();
		If Types.Count() > 1 Then
			Continue;
		EndIf;
		
		AttributeObject = Metadata.FindByType(Types[0]);
		If AttributeObject = Undefined Then
			Continue;
		EndIf;
		NewRow.NameOfMetadataObjects = AttributeObject.FullName();
		
		If Metadata.Catalogs.Contains(AttributeObject)
				Or Metadata.Documents.Contains(AttributeObject)
				Or Metadata.BusinessProcesses.Contains(AttributeObject)
				Or Metadata.Tasks.Contains(AttributeObject)
				Or Metadata.ChartsOfCharacteristicTypes.Contains(AttributeObject)
				Or Metadata.ChartsOfAccounts.Contains(AttributeObject) Then
			
			NewRow.ThereAreAttributes = True;
			NewRow.GetItems().Add();
			
		EndIf;
		
	EndDo;
	
	NewRow = TreeItems.Add();
	NewRow.Name = "Presentation";
	NewRow.Path = RowData.Path + "." + "Presentation";
	NewRow.Presentation = NStr("vi = 'Trình bày';
								|ru = 'Представление';
								|en = 'Presentation'; fa = 'نمایش';
								|it = 'Visualizzazione';
								|pl = 'Presentation';
								|tr = 'Sunum'");
	NewRow.PathPresentation = RowData.PathPresentation + "." + NStr("vi = 'Trình bày';
																	|ru = 'Представление';
																	|en = 'Presentation'; fa = 'نمایش';
																	|it = 'Visualizzazione';
																	|pl = 'Presentation';
																	|tr = 'Sunum'");
	NewRow.Type = "String";
	
	For Each Attribute In Object.Attributes Do
		
		If StrStartsWith(Attribute.Name, "Delete") Then
			Continue;
		EndIf;
	
		Presentation = Attribute.Presentation();
		
		NewRow = TreeItems.Add();
		NewRow.Name = Attribute.Name;
		NewRow.Path = RowData.Path + "." + Attribute.Name;
		NewRow.Presentation =  Presentation;
		NewRow.PathPresentation =  RowData.PathPresentation + "." + Presentation;
		NewRow.Type = Attribute.Type;
		
		Types = Attribute.Type.Types();
		If Types.Count() > 1 Then
			Continue;
		EndIf;
			
		AttributeObject = Metadata.FindByType(Types[0]);
		If AttributeObject = Undefined Then
			Continue;
		EndIf;
		NewRow.NameOfMetadataObjects = AttributeObject.FullName();
		
		If Metadata.Catalogs.Contains(AttributeObject)
				Or Metadata.Documents.Contains(AttributeObject)
				Or Metadata.BusinessProcesses.Contains(AttributeObject)
				Or Metadata.Tasks.Contains(AttributeObject)
				Or Metadata.ChartsOfCharacteristicTypes.Contains(AttributeObject)
				Or Metadata.ChartsOfAccounts.Contains(AttributeObject) Then
			NewRow.ThereAreAttributes = True;
			NewRow.GetItems().Add();
		EndIf;
		
	EndDo;
	
EndProcedure
	
#EndRegion
