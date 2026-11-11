#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	
	If Parameters.ThisIsTable Then
		Title = NStr("vi = 'Chọn bảng 1C:Document Management';
					|ru = 'Выбор таблицы 1С:Документооборота';
					|en = 'Select 1C:Document Management table'; fa = 'Select 1C:Document Management table';
					|it = 'Selezione tabella di 1C:Document Management';
					|pl = 'Wybór tabeli 1C:Document Management';
					|tr = '1C:Document Management tablosu seç'");
	Else
		Title = NStr("vi = 'Chọn mục tin 1C:Document Management';
					|ru = 'Выбор реквизита 1С:Документооборота';
					|en = 'Select 1C:Document Management attribute'; fa = 'Select 1C:Document Management attribute';
					|it = 'Selezione attributo di 1C:Document Management';
					|pl = 'Wybór atrybutu 1С:Document Management';
					|tr = '1C:Document Management özniteliği seçimi'");
	EndIf;
	
	FIllAttributeTree(
		Parameters.ObjectAttributesBefore,
		Parameters.AttributeNameObjectDM,
		Parameters.ObjectAttributePresentationIS,
		Parameters.ThisIsTable,
		Parameters.Table);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributeTree

&AtClient
Procedure AttributeTreeValueChoice(Item, Value, StandardProcessing)
	
	ChooseValueOfAttribute();
	
EndProcedure

&AtClient
Procedure AttributeTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
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
			Or (CurrentData.Name = "" And Not CurrentData.IsAdditionalAttributeDM)
			Or CurrentData.Unavailable Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Name", ?(ValueIsFilled(CurrentData.Table),
		StrTemplate("%1.%2", CurrentData.Table, CurrentData.Name),
		CurrentData.Name));
	Result.Insert("Presentation", CurrentData.Presentation);
	Result.Insert("IsAdditionalAttributeDM", CurrentData.IsAdditionalAttributeDM);
	Result.Insert("AdditionalAttributeDMID", CurrentData.AdditionalAttributeDMID);
	Result.Insert("AdditionalAttributeDMType", CurrentData.AdditionalAttributeDMType);
	Result.Insert("ThisIsTable", CurrentData.ThisIsTable);
	Result.Insert("Table", CurrentData.Table);
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure FIllAttributeTree(ObjectAttributesBefore, AttributeNameObjectDM, ObjectAttributePresentationIS,
		ThisIsTable, Table)
	
	Tree = FormAttributeToValue("AttributeTree");
	
	TreeLevel = Tree.Rows;
	
	For Each Attribute In ObjectAttributesBefore Do // See IntegrationWith1CDocumentManagementCoreClientServer.AttributeData
		
		// Tables are filled with tables only.
		If ThisIsTable And Not Attribute.ThisIsTable Then
			Continue;
		EndIf;
		
		If Attribute.Table = "" Then
			TreeLevel = Tree.Rows;
		EndIf;
		
		NewRow = TreeLevel.Add();
		FillPropertyValues(NewRow, Attribute);
		If Attribute.ThisIsTable Then
			TreeLevel = NewRow.Rows;
			NewRow.Type = NStr("vi = 'Bảng';
								|ru = 'Таблица';
								|en = 'Table'; fa = 'جدول';
								|it = 'Tabella';
								|pl = 'Table';
								|tr = 'Tablo'");
		Else
			NewRow.Type = IntegrationWith1CDocumentManagementCore.ObjectTypePresentationXDTO(
				String(Attribute.Type),
				True);
		EndIf;
		
		// The details of a table cannot be filled in with the details of another table.
		If ValueIsFilled(Table) And ValueIsFilled(Attribute.Table) And Table <> Attribute.Table Then
			NewRow.Unavailable = True;
		EndIf;
		
		// The props cannot be filled in with another table.
		If Attribute.ThisIsTable And Not ThisIsTable Then
			NewRow.Unavailable = True;
		EndIf;
		
		// The usual props cannot be filled in with the props of the table or the table itself.
		If Not ValueIsFilled(Table) And Not ThisIsTable
				And (ValueIsFilled(Attribute.Table) Or Attribute.ThisIsTable) Then
			NewRow.Unavailable = True;
		EndIf;
		
		NewRow.Highlighted = ValueIsFilled(Table) And Attribute.ThisIsTable And Table = Attribute.Name;
		
	EndDo;
	
	Tree.Rows.Sort("ThisIsTable, IsAdditionalAttributeDM, Presentation");
	
	For Each String In Tree.Rows Do
		If String.ThisIsTable Then
			String.Rows.Sort("Presentation");
		EndIf;
	EndDo;
	
	ValueToFormAttribute(Tree, "AttributeTree");
	
	// Let's find the table.
	If ValueIsFilled(Table) Then
		For Each TreeItem In AttributeTree.GetItems() Do
			If TreeItem.ThisIsTable
				And TreeItem.Name = Table Then
				Items.AttributeTree.CurrentRow = TreeItem.GetID();
			EndIf;
		EndDo;
	EndIf;
	
	// We will find the previously selected props.
	If ValueIsFilled(AttributeNameObjectDM) Then
		For Each TreeItem In AttributeTree.GetItems() Do
			If TreeItem.Name = AttributeNameObjectDM
				And TreeItem.Table = Table Then
				Items.AttributeTree.CurrentRow = TreeItem.GetID();
				Return;
			EndIf;
			If TreeItem.ThisIsTable Then
				For Each SubordinateItem In TreeItem.GetItems() Do
					If StrTemplate("%1.%2", SubordinateItem.Table, SubordinateItem.Name) = AttributeNameObjectDM Then
						Items.AttributeTree.CurrentRow = SubordinateItem.GetID();
						Return;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// We will find a suitable one according to the presentation.
	For Each TreeItem In AttributeTree.GetItems() Do
		If TreeItem.Presentation = ObjectAttributePresentationIS
			And TreeItem.Table = Table Then
			Items.AttributeTree.CurrentRow = TreeItem.GetID();
		EndIf;
		If TreeItem.ThisIsTable Then
			For Each SubordinateItem In TreeItem.GetItems() Do
				If SubordinateItem.Presentation = ObjectAttributePresentationIS
					And SubordinateItem.Table = Table Then
					Items.AttributeTree.CurrentRow = SubordinateItem.GetID();
					Return;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion