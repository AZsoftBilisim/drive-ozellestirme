
&AtClient
Procedure Select(Command)
	
	ProcessSelection(Items.SelectionTree.CurrentRow);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Currency") Then
		WorkMode = 2;
		Title = NStr("vi = 'Phương pháp xác định tiền tệ';
					|ru = 'Способ определения валюты';
					|en = 'Currency determination method'; fa = 'Currency determination method';
					|it = 'Metodo per determinare la valuta';
					|pl = 'Sposób określania waluty';
					|tr = 'Para birimini tanımlama yöntemi'");
	ElsIf Parameters.Property("Count") Then
		WorkMode = 1;
		Title = NStr("vi = 'Phương pháp xác định đơn vị tính';
					|ru = 'Способ определения ед. измерения';
					|en = 'Method of determining a unit of measure'; fa = 'Method of determining a unit of measure';
					|it = 'Metodo per determinare l''unità di misura';
					|pl = 'Sposób określania jed. miary';
					|tr = 'Ölçü bilimini tanımlama yöntemi'");
	Else
		Raise NStr("vi = 'Chế độ hoạt động không xác định';
					|ru = 'Неизвестный режим работы';
					|en = 'Unknown operation mode'; fa = 'Unknown operation mode';
					|it = 'Modalità di lavoro sconosciuta';
					|pl = 'Nieznany tryb pracy';
					|tr = 'Bilinmeyen çalışma modu'");
	EndIf;
	
	ValueTypes = Parameters.ValueTypes;
	
	ImageCache_ = New Structure("Item, Catalog", PictureLib.Item, PictureLib.Catalog);
	
	Tree = FormAttributeToValue("SelectionTree");
	
	Types = ValueTypes.Types();
	If Types.Count() = 1 Then
		NewRow = Tree.Rows.Add();
		NewRow.Presentation = Types[0];
		NewRow.Picture = ImageCache_.Catalog;
		TreeRows = NewRow.Rows;
	Else
		TreeRows = Tree.Rows;
	EndIf;
	
	FillInAnalyticsDetails(TreeRows, ValueTypes, ImageCache_);
	RemoveUnusedBranches(TreeRows);
	
	ValueToFormAttribute(Tree, "SelectionTree");
	
EndProcedure

&AtServer
Procedure RemoveUnusedBranches(Rows)
	
	Delete = New Array;
	For Each String In Rows Do
		If Not String.Rows.Total("Searchable", True)
			And Not String.Searchable Then
			Delete.Add(String);
		Else
			RemoveUnusedBranches(String.Rows);
		EndIf;
	EndDo;
	
	For Each ArrayElement In Delete Do
		Rows.Delete(ArrayElement);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAnalyticsDetails(ElementsOfParentRow, TypeDescription, ImageCache_, Level = 0)
	
	If Level = 4 Then
		Return;
	EndIf;
	
	AttributeTypes = TypeDescription.Types();
	
	For Each AttributeType In AttributeTypes Do
		
		ItemMetadata = Metadata.FindByType(AttributeType);
		If ItemMetadata = Undefined Then
			Continue;
		EndIf;
		
		If AttributeTypes.Count() = 1 Then
			RowItems = ElementsOfParentRow;
		Else
			NewRow = ElementsOfParentRow.Add();
			NewRow.Presentation = AttributeType;
			NewRow.Value = "<type>";
			NewRow.Picture = ImageCache_.Catalog;
			RowItems = NewRow.Rows;
		EndIf;
				
		Try
			Attributes = ItemMetadata.Attributes;
		Except
			Continue;
		EndTry;
		
		ArrayOfCurrencies = New Array;
		For Each Attribute In Attributes Do
			
			Types = Attribute.Type.Types();
			
			If Types.Find(Type("CatalogRef.LabelAndPriceTagTemplates")) <> Undefined Then
				Continue;
			EndIf;
			
			ThereIsTypeYouAreLookingFor = False;
			If Types.Count() = 1 Then
				SearchableType = ?(WorkMode = 1, Type("CatalogRef.PackagesAndUnitsOfMeasure"), Type("CatalogRef.Currencies"));
				ThereIsTypeYouAreLookingFor = Types.Find(SearchableType) <> Undefined;
			EndIf;
			
			NewRow = RowItems.Add();
			NewRow.Presentation = Attribute.Synonym;
			NewRow.Value = Attribute.Name;
			NewRow.Searchable = ThereIsTypeYouAreLookingFor;
			NewRow.Picture = ImageCache_.Item;
			
			If ThereIsTypeYouAreLookingFor Then
				Continue;
			EndIf;
			
			PropsElements = NewRow.Rows;
			
			FillInAnalyticsDetails(PropsElements, Attribute.Type, ImageCache_, Level + 1);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TreeItems = SelectionTree.GetItems();
	If TreeItems.Count() Then
		IDOfFirstLine = TreeItems[0].GetID();
		Items.SelectionTree.Expand(IDOfFirstLine);
	EndIf;
		
EndProcedure

&AtClient
Procedure SelectionTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection(RowSelected);
	
EndProcedure

&AtClient
Procedure ProcessSelection(RowSelected)
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	TreeRow = SelectionTree.FindByID(RowSelected);
	StringIsSuitableForSelection = TreeRow.Searchable Or TypeOf(TreeRow.Value) = Type("CatalogRef.PackagesAndUnitsOfMeasure");
	If Not StringIsSuitableForSelection Then
		ShowMessageBox(, NStr("vi = 'Không thể chọn dòng!';
								|ru = 'Строка не может быть выбрана!';
								|en = 'Line cannot be selected.'; fa = 'Line cannot be selected.';
								|it = 'La riga non può essere selezionata!';
								|pl = 'Wiersz nie może zostać wybrany!';
								|tr = 'Satır seçilemiyor!'"));
		Return;
	EndIf;
	
	If TypeOf(TreeRow.Value) = Type("CatalogRef.PackagesAndUnitsOfMeasure") Then
		Value = TreeRow.Value;
		Presentation = TreeRow.PresentationOfSelectionOption;
	Else
		Parent = TreeRow;
		Value = "";
		Presentation = "";
		While Parent <> Undefined Do
			If Parent.Value <> "<type>"
				And ValueIsFilled(Parent.Value) Then
				Value = Parent.Value + ?(Not IsBlankString(Value), ".", "") + Value;
				Presentation = "[" + Parent.Presentation + "]" + 
					?(Not IsBlankString(Presentation), ".", "") + Presentation;
			EndIf;
			Parent = Parent.GetParent();
		EndDo;
	EndIf;
	
	Close(New Structure("Value, Presentation", Value, Presentation));
	
EndProcedure