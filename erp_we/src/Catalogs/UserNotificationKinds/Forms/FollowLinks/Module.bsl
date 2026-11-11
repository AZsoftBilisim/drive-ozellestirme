#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not TypeOf(Parameters.RefsMap) = Type("Map") Then
		Raise(NStr("vi = 'Đã truyền dữ liệu không hợp lệ vào biểu mẫu.';
					|ru = 'В форму переданы некорректные данные.';
					|en = 'Incorrect data is sent to the form.'; fa = 'Incorrect data is sent to the form.';
					|it = 'Incorrect data is sent to the form.';
					|pl = 'Incorrect data is sent to the form.';
					|tr = 'Forma hatalı veriler aktarıldı.'"),ErrorCategory.ConfigurationError);
	EndIf;
	
	For Each MapItem In Parameters.RefsMap Do
		NewRow = TypesTable.Add();
		MetadataObject = Common.MetadataObjectByFullName(MapItem.Key);
		NewRow.TableName = MapItem.Key;
		NewRow.ReferenceList.LoadValues(MapItem.Value);
		NewRow.FormName = StrTemplate("%1.%2", NewRow.TableName, "ListForm");
		ListPresentation = Common.ListPresentation(MetadataObject);
		If Not AccessRight("View", MetadataObject) Then
			ListPresentation = NStr("vi = '<không thể xem danh sách đối tượng>';
									|ru = '<список объектов недоступен для просмотра>';
									|en = '<the list of objects is not available for preview>'; fa = '<the list of objects is not available for preview>';
									|it = '<the list of objects is not available for preview>';
									|pl = '<the list of objects is not available for preview>';
									|tr = '<nesne listesi görüntülenemez>'");
			NewRow.FormName = "";
		EndIf;
		NewRow.Presentation = StrTemplate("%1 (%2)", ListPresentation, MapItem.Value.Count());
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesTable

&AtClient
Procedure TypesTableSelection(Item, RowSelected, Field, StandardProcessing)
	GoToListForm();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToForm(Command)
	GoToListForm();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToListForm()
	
	CurrentData = Items.TypesTable.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.FormName) Then
		StructureFilter = New Structure("Ref", CurrentData.ReferenceList);
		OpeningParameters = New Structure("Filter", StructureFilter);
		OpenForm(CurrentData.FormName, OpeningParameters);
		Close();
	EndIf;
EndProcedure

#EndRegion
