////////////////////////////////////////////////////////////////////////////////
// The "Set of Server Calls" module contains procedures and functions for
// working with sets.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks whether the field is a blocked element of the sets subsystem
// 
// Parameters:
//  Field - FormField - Form field.
//
// Returns:
//  Boolean - Test result
Function ItemToLock(Field) Export
	
	ItemsToLock = SetsClientServer.ItemsToLock();
	
	If ItemsToLock.Find(Field.Name) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction


// Pre-Delete event handler procedure
// 
// Parameters:
//  FormData1 - ClientApplicationForm - 
//  TSName       - String - name of the table part
//  Cancel       - Boolean - 
//  Copy - Boolean - 
//  NameOfNotificationHandler - String - 
//
Procedure BeforeDeletingRowOfTablePart(FormData1, TSName, Cancel, Copy = False, NameOfNotificationHandler = "WhenRemovingComponents") Export
	
	Form = GetManagedForm(FormData1);
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
		TS = Form.Object[TSName];
	Else
		TS = Form[TSName];
	EndIf;
	
	If Form.Items[TSName].SelectedRows.Count() = TS.Count() Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Sets", New Array);
	Parameters.Insert("Other", New Array);
	Parameters.Insert("TSName", TSName);
	Parameters.Insert("Copy", Copy);
	
	FoundSet = False;
	For Each IDOfSelectedRow_ In Form.Items[TSName].SelectedRows Do
		TSRow = TS.FindByID(IDOfSelectedRow_);
		If TMCommonUseClientServer.HasObjectAttribute(TSRow, "ProductsInSet")
			And ValueIsFilled(TSRow.ProductsInSet)Then
			FoundSet = True;
			
			SetParameters = New Structure;
			SetParameters.Insert("ProductsInSet", TSRow.ProductsInSet);
			SetParameters.Insert("ItemVariantOfSet", TSRow.ItemVariantOfSet);
			
			If TMCommonUseClientServer.HasObjectAttribute(TSRow, "SalesOrder") Then
				SetParameters.Insert("SalesOrder", TSRow.SalesOrder);
			EndIf;
			If TMCommonUseClientServer.HasObjectAttribute(TSRow, "DocumentSalesOfGoodsAndServices") Then
				SetParameters.Insert("DocumentSalesOfGoodsAndServices", TSRow.DocumentSalesOfGoodsAndServices);
			EndIf;
			If TMCommonUseClientServer.HasObjectAttribute(TSRow, "RowCode") And TSRow.RowCode = 0 Then
				SetParameters.Insert("RowCode", 0);
			EndIf;
			
			SetAdded = False;
			For Each SetRow In Parameters.Sets Do
				ThereAreDifferences = False;
				For Each KeyAndValue In SetParameters Do
					If SetRow[KeyAndValue.Key] <> KeyAndValue.Value Then
						ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If Not ThereAreDifferences Then
					SetAdded = True;
					Break;
				EndIf;
			EndDo;
			
			If Not SetAdded Then
				Parameters.Sets.Add(SetParameters);
			EndIf;
			
		Else
			Parameters.Other.Add(TSRow.GetID());
		EndIf;
	EndDo;
	
	If FoundSet Then
		
		CallbackDescription = New CallbackDescription(NameOfNotificationHandler, Form, Parameters);
		
		OpenForm("DataProcessor.EditSet.Form.RemoveSetRows",
			Parameters,
			Form,
			Form.UUID,,,
			CallbackDescription);
		Cancel = True;
		
	EndIf;
	
EndProcedure

// Procedure handler for the Delete event
// 
// Parameters:
//  Form     - Form - 
//  TSName     - String - name of the table part
//  Parameters - Structure - (Sets, Other).
//
Procedure WhenRemovingComponents(Form, TSName, Parameters) Export
	
	SetParameters = Parameters.Sets[0];
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("ProductsInSet",   SetParameters.ProductsInSet);
	NotificationParameter1.Insert("ItemVariantOfSet", SetParameters.ItemVariantOfSet);
	If SetParameters.Property("DocumentSalesOfGoodsAndServices") Then
		NotificationParameter1.Insert("DocumentSalesOfGoodsAndServices", SetParameters.DocumentSalesOfGoodsAndServices);
	EndIf;
	If SetParameters.Property("SalesOrder") Then
		NotificationParameter1.Insert("SalesOrder", SetParameters.SalesOrder);
	EndIf;
	NotificationParameter1.Insert("OwnerForm",        Form.UUID);
	NotificationParameter1.Insert("TSName",                TSName);
	
	Notify("EditSet", NotificationParameter1, Form);
	
EndProcedure

// Procedure for checking the filling in part of sets
// 
// Parameters:
//  Form     - FormDataStructure - must contain, among other things:
//    * Goods - ValueTable, TabularSection - 
//  Cancel     - Boolean - 
//
Procedure CheckFilling(Form, Cancel) Export
	
	If Not ValueIsFilled(Form.PriceDistributionOption) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Phương án phân bổ đơn giá"".';
						|ru = 'Не заполнено поле ""Вариант распределения цены"".';
						|en = '""Price allocation option"" is required.'; fa = '""Price allocation option"" is required.';
						|it = 'Il campo ""Opzione di distribuzione dei Prezzi"" non è compilato.';
						|pl = 'Nie jest wypełnione pole ""Вариант распределения цены"".';
						|tr = '""Fiyat dağıtım seçeneği"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"PriceDistributionOption",
			,
			Cancel);
	EndIf;
	
	If Form.Goods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chưa nhập bất kỳ dòng nào vào danh sách ""Thành phần chi tiết"".';
						|ru = 'Не введено ни одной строки в список ""Комплектующие"".';
						|en = 'No line is entered into the ""Components"" list.'; fa = 'No line is entered into the ""Components"" list.';
						|it = 'Non è stata inserita alcuna riga nell''elenco ""Componenti"".';
						|pl = 'Nie wprowadzono żadnego wiersza do listy ""Комплектующие"".';
						|tr = '""Bileşenler"" listesine hiçbir satır girilmedi.'");
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"Goods",
			,
			Cancel);
	EndIf;
	
	For Each TSRow In Form.Goods Do
		
		LineNumber = Form.Goods.IndexOf(TSRow) + 1;
		
		If Not ValueIsFilled(TSRow.Products) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Mặt hàng"" tại dòng ""%LineNumber%"" trong danh sách ""Thành phần chi tiết""';
							|ru = 'Не заполнена колонка ""Номенклатура"" в строке ""%LineNumber%"" списка ""Комплектующие""';
							|en = 'Column ""Items"" in line ""%LineNumber%"" of the ""Components"" list is not filled in'; fa = 'Column ""Items"" in line ""%LineNumber%"" of the ""Components"" list is not filled in';
							|it = 'Non è compilata la colonna ""Nomenclatura"" nella riga %LineNumber% dell''elenco ""Componenti"".';
							|pl = 'Nie wypełniono kolumny ""Номенклатура"" w wierszu ""%LineNumber%"" listy ""Комплектующие""';
							|tr = '""Bileşenler"" listesinin ""%LineNumber%"" satırında ""Öğe"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("Goods", LineNumber, "Products"),
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(TSRow.Characteristic) And TSRow.ItemVariantsAreUsed Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Đặc tính"" tại dòng ""%LineNumber%"" trong danh sách ""Thành phần chi tiết""';
							|ru = 'Не заполнена колонка ""Характеристика"" в строке ""%LineNumber%"" списка ""Комплектующие""';
							|en = 'Column ""Variant"" in line ""%LineNumber%"" of the ""Components"" list is not filled in'; fa = 'Column ""Variant"" in line ""%LineNumber%"" of the ""Components"" list is not filled in';
							|it = 'Non è compilata la colonna ""Caratteristica"" nella riga %LineNumber% dell''elenco ""Componenti"".';
							|pl = 'Nie wypełniono kolumny ""Характеристика"" w wierszu ""%LineNumber%"" listy ""Комплектующие""';
							|tr = '""Bileşenler"" listesinin ""%LineNumber%"" satırında ""Varyant"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("Goods", LineNumber, "Characteristic"),
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(TSRow.NumberOfPackages) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Số lượng"" tại dòng ""%LineNumber%"" trong danh sách ""Thành phần chi tiết""';
							|ru = 'Не заполнена колонка ""Количество"" в строке ""%LineNumber%"" списка ""Комплектующие""';
							|en = 'Column ""Quantity"" in line ""%LineNumber%"" of the ""Components"" list is not filled in'; fa = 'Column ""Quantity"" in line ""%LineNumber%"" of the ""Components"" list is not filled in';
							|it = 'Non è compilata la colonna ""Quantità"" nella riga %LineNumber% dell''elenco ""Componenti""';
							|pl = 'Nie wypełniono kolumny ""Количество"" w wierszu ""%LineNumber%"" listy ""Комплектующие""';
							|tr = '""Miktar"" sütunu, ""Bileşenler"" listesinin ""%LineNumber%"" satırında doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("Goods", LineNumber, "NumberOfPackages"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// The procedure supplements the array of rows in the table part with the remaining rows of sets,
// if the specified sets are not fully represented in the array of rows.
// 
// Parameters:
//  TabularSection - TabularSection - 
//  RowsArray - Array of LineOfATabularSection - 
//
Procedure AddToFullSet(TabularSection, RowsArray) Export
	
	LinesToAdd = New Array;
	
	For Each TSRow In RowsArray Do
		
		If ValueIsFilled(TSRow.ProductsInSet) Then
			
			Filter = New Structure;
			Filter.Insert("ProductsInSet", TSRow.ProductsInSet);
			Filter.Insert("ItemVariantOfSet", TSRow.ItemVariantOfSet);
			
			FoundRows = TabularSection.FindRows(Filter);
			For Each FoundRow In FoundRows Do
				If RowsArray.Find(FoundRow) = Undefined Then
					 LinesToAdd.Add(FoundRow);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	For Each TSRow In LinesToAdd Do
		RowsArray.Add(TSRow);
	EndDo;
	
EndProcedure

// This procedure controls the visibility of elements in the set composition configuration forms
// if the specified sets are not fully represented in the array of strings.
// 
// Parameters:
// 	Form - ClientApplicationForm - 
//
Procedure ChangeVisibilityOfSettingsRestrictionWarning(Form) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "PresentationOptionInPrintForms") Then
		PresentationOptionInPrintForms = Form.PresentationOptionInPrintForms;
	Else
		PresentationOptionInPrintForms = Form.Object.PresentationOptionInPrintForms;
	EndIf;
	
	PricingOption = Form.PricingOption;
	
	Form.Items.GroupWarningSets.Visible = 
		(PresentationOptionInPrintForms = PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.OnlySet")
		Or PricingOption = 1);
		
EndProcedure

// The function checks whether the "edit Set" action is executed.
// 
// Parameters:
//  Action - String - Required action.
//
// Returns:
//  Boolean - This is the "Edit Set" action.
//
Function EditSetAction(Action) Export
	Return Action = "EditSet"
EndFunction

// The function checks the execution of the "delete Allset" action.
// 
// Parameters:
//  Action - String - Required action.
//
// Returns:
//  Boolean - This is the "Delete the entire Set" action.
//
Function DeleteEntireSetAction(Action) Export
	Return Action = "DeleteEntireSet"
EndFunction

#EndRegion

#Region Private

// Parameters:
// 	FormData1 - ClientApplicationForm - 
// Returns:
// 	ClientApplicationForm - contains including:
// 		* Object - DocumentObject - 
Function GetManagedForm(FormData1)
	
	If TypeOf(FormData1) = Type("ClientApplicationForm") Then
		Return FormData1;
	Else
		Return GetManagedForm(FormData1.Parent);
	EndIf;
	
EndFunction

#EndRegion
