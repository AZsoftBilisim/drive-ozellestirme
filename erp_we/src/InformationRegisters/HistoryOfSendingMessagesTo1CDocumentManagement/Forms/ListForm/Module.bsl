#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByIDOnChange(Item)
	
	If Not ValueIsFilled(ByID) Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Id",
			Undefined,
			DataCompositionComparisonType.Equal,,
			False);
		Return;
	EndIf;
	
	Try
		Id = New UUID(ByID);
	Except
		ShowMessageBox(, NStr("vi = 'Sai tên định danh';
								|ru = 'Идентификатор неверен';
								|en = 'ID is incorrect'; fa = 'ID is incorrect';
								|it = 'ID non autentico';
								|pl = 'Identyfikator jest niepoprawny';
								|tr = 'Kimlik geçersiz'"));
		CommonClientServer.SetDynamicListFilterItem(List,
			"Id",
			Undefined,
			DataCompositionComparisonType.Equal,,
			False);
		Return;
	EndTry;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Id",
		Id,
		DataCompositionComparisonType.Equal,,
		True);
	
EndProcedure

#EndRegion