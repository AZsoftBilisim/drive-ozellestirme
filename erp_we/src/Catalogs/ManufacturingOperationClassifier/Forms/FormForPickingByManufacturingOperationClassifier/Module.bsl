#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CloseOnChoice = False;
	
	FillInClassifier();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersClassifier

&AtClient
Procedure ClassifierSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ClassifierSelectionOnClient(RowSelected);
	
EndProcedure

&AtClient
Procedure ClassifierValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	ClassifierSelectionOnClient(Value);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Classifier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Classifier.ExistingRef");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.FieldSelectionBackColor);

EndProcedure

&AtServer
Procedure FillInClassifier()
	
	Template = Catalogs.ManufacturingOperationClassifier.GetTemplate("ManufacturingOperationClassifierTemplate");
	
	XMLReader = New XMLReader();
	XMLReader.SetString(Template.GetText());
	
	CurrentRow = Undefined; // FormDataTreeItem
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			TagName = XMLReader.Name;
			If XMLReader.Name = "Item" Then
				Collection = ?(CurrentRow = Undefined, Classifier, CurrentRow);
				CurrentRow = Collection.GetItems().Add();
			EndIf;
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			If XMLReader.Name = "Item" Then
				CurrentRow = CurrentRow.GetParent();
			EndIf;
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			CurrentRow[TagName] = XMLReader.Value;
		EndIf;
		
	EndDo;
	
	FillInServiceAttributesOfClassifierTree();
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfClassifierTree()
	
	SearchAttributes = "Code,IsFolder";
	
	ExistingItems = ExistingItems();
	ExistingItems.Indexes.Add(SearchAttributes);
	
	Filter = New Structure(SearchAttributes);
	
	For Each GroupString In Classifier.GetItems() Do
		
		GroupString.IsFolder = True;
		FillInServiceAttributesOfClassifierTreeLine(GroupString, ExistingItems, Filter);
		
		For Each String In GroupString.GetItems() Do
			FillInServiceAttributesOfClassifierTreeLine(String, ExistingItems, Filter);
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfClassifierTreeLine(RowData, ExistingItems, Filter)
	
	FillPropertyValues(Filter, RowData);
	
	FoundRows = ExistingItems.FindRows(Filter);
	If ValueIsFilled(FoundRows) Then
		RowData.ExistingRef = FoundRows[0].ExistingRef;
	EndIf;
	
	RowData.PictureIndex = ?(RowData.IsFolder, 2, 5);
	
EndProcedure

&AtServer
Function ExistingItems()
	
	QueryText = "
	|SELECT
	|	Classifier.Ref    AS ExistingRef,
	|	Classifier.Code       AS Code,
	|	Classifier.IsFolder AS IsFolder
	|FROM
	|	Catalog.ManufacturingOperationClassifier AS Classifier";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

&AtClient
Procedure ClassifierSelectionOnClient(RowsSelected)
	
	If ThereAreGroupsInSelection(RowsSelected) Then
		AdditionalParameters = New Structure("RowsSelected", RowsSelected);
		ShowQueryBox(
			New CallbackDescription("AddNestedCompletion", ThisObject, AdditionalParameters),
			NStr("vi = 'Đối với các nhóm được chọn, thêm tất cả phần tử lồng trong?';
				|ru = 'Для выбранных групп добавить все вложенные элементы?';
				|en = 'Add all the nested items for the selected groups?'; fa = 'Add all the nested items for the selected groups?';
				|it = 'Add all the nested items for the selected groups?';
				|pl = 'Add all the nested items for the selected groups?';
				|tr = 'Seçilen gruplar için tüm ek öğeler eklensin mi?'"),
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	If ClassifierSelectionOnServer(RowsSelected) Then
		NotifyFormAndUser();
	EndIf;
	
EndProcedure

&AtClient
Procedure AddNestedCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		If ClassifierSelectionOnServer(AdditionalParameters.RowsSelected, Result = DialogReturnCode.Yes) Then
			NotifyFormAndUser();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ClassifierSelectionOnServer(Val RowsSelected, AddNested = False)
	
	ItemsWereAdded = False;
	
	For Each RowID In RowsSelected Do
		RowData = Classifier.FindByID(RowID);
		If RowData.IsFolder Then
			AddToClassifier(RowData, ItemsWereAdded);
		EndIf;
	EndDo;
	
	For Each RowID In RowsSelected Do
		RowData = Classifier.FindByID(RowID);
		If RowData.IsFolder Then
			If AddNested Then
				For Each SubordinateRow In RowData.GetItems() Do
					AddToClassifier(SubordinateRow, ItemsWereAdded, RowData.ExistingRef);
				EndDo;
			EndIf;
		Else
			AddToClassifier(RowData, ItemsWereAdded);
		EndIf;
	EndDo;
	
	Return ItemsWereAdded;
	
EndFunction

&AtClient
Function ThereAreGroupsInSelection(RowsSelected)
	
	For Each RowID In RowsSelected Do
		RowData = Classifier.FindByID(RowID);
		If RowData.IsFolder Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function AddToClassifier(RowData, ItemsWereAdded, Parent = Undefined)
	
	If ValueIsFilled(RowData.ExistingRef) Then
		Return RowData.ExistingRef;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If RowData.IsFolder Then
		NewObject = Catalogs.ManufacturingOperationClassifier.CreateFolder();
	Else
		NewObject = Catalogs.ManufacturingOperationClassifier.CreateItem();
	EndIf;
	
	If Parent = Undefined Then
		RowParent = RowData.GetParent();
		If RowParent <> Undefined Then
			Parent = RowParent.ExistingRef;
		EndIf;
	EndIf;
	
	NewObject.Fill(Undefined);
	FillPropertyValues(NewObject, RowData);
	NewObject.Parent = Parent;
	NewObject.Write();
	
	RowData.ExistingRef = NewObject.Ref;
	ItemsWereAdded = True;
	
	Return NewObject.Ref;
	
EndFunction

&AtClient
Procedure NotifyFormAndUser()
	
	NotifyChanged(Type("CatalogRef.ManufacturingOperationClassifier"));
	
	ShowUserNotification(
		NStr("vi = 'Lưu';
			|ru = 'Сохранение';
			|en = 'Save'; fa = 'ذخیره';
			|it = 'Save';
			|pl = 'Save';
			|tr = 'Kayıt'"),,
		NStr("vi = 'Đã thêm phần tử mới của bảng phân loại';
			|ru = 'Новые элементы классификатора добавлены';
			|en = 'New classifier items are added'; fa = 'New classifier items are added';
			|it = 'New classifier items are added';
			|pl = 'New classifier items are added';
			|tr = 'Yeni sınıflandırıcı öğeleri eklendi'"),
		PictureLib.Information32);
	
EndProcedure

#EndRegion