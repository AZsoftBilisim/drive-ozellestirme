///////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF INTERACTIVE WORK WITH MULTI-TURN PACKAGING

#Region Public

// Opens the multi-turn container selection form in the document
//
// Parameters:
// Form - ClientApplicationForm - The form from which multi-turn packaging is selected
// TableName - String - Name of the table with the products and packaging of the document
// ColumnsNames - String - Comma-separated names of columns in the table with products and packaging of the document.
// CallbackDescription - CallbackDescription - Notification description
//
Procedure SelectReusablePackage(Val Form,
	                                  Val TableName,
	                                  Val ColumnsNames,
	                                  CallbackDescription = Undefined) Export
	
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ColumnsNames, ",");
	
	If ColumnsArray1.Count() = 6 Then
		ShowWarehouse = ValueIsFilled(ColumnsArray1[3]);
		ShowDate = ValueIsFilled(ColumnsArray1[4]);
		ShowReceiptDate = ValueIsFilled(ColumnsArray1[5]);
	ElsIf ColumnsArray1.Count() = 5 Then
		ShowWarehouse = ValueIsFilled(ColumnsArray1[3]);
		ShowDate = ValueIsFilled(ColumnsArray1[4]);
		ShowReceiptDate = False;
	ElsIf ColumnsArray1.Count() = 4 Then
		ShowWarehouse = ValueIsFilled(ColumnsArray1[3]);
		ShowDate = False;
		ShowReceiptDate = False;
	ElsIf ColumnsArray1.Count() = 3 Then
		ShowWarehouse = False;
		ShowDate = False;
		ShowReceiptDate = False;
	Else
		
		ErrorDescription = NStr("vi = 'Đã đặt sai tham số %1 hàm';
								|ru = 'Неверно задан параметр %1 функции';
								|en = '%1 function parameter is specified incorrectly'; fa = '%1 function parameter is specified incorrectly';
								|it = 'Parametro %1 della funzione non dato correttamente';
								|pl = 'Niepoprawnie zadano parametr %1 funkcji';
								|tr = 'Yanlış fonksiyon parametresi %1'");
		ErrorDescription = StrTemplate(ErrorDescription, "ColumnsNames");
		
		Raise ErrorDescription;
	EndIf;
	
	If Form.Object[TableName].Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Không có dòng nào trong danh sách. Không cần điền lại bao bì luân chuyển.';
								|ru = 'В списке отсутствуют строки. Дозаполнение многооборотной тарой не требуется.';
								|en = 'No lines in the list. Do not fill it in with reusable packaging.'; fa = 'No lines in the list. Do not fill it in with reusable packaging.';
								|it = 'Non ci sono righe nell''elenco. Non è necessario il riempimento di una tara multirotale.';
								|pl = 'W liście brakują wierszy. Wypełnienie dodatkowe tarą wieloobrotową nie jest potrzebne.';
								|tr = 'Listede satır mevcut değil. Yeniden kullanılabilir ambalajla yeniden doldurma gerekli değildir.'"));
		
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, False);
		EndIf;
		
		Return;
		
	EndIf;
	
	AddressOfTheGoodsInTheTemporaryStorage = ReusablePackageServerCall.PlaceGoodsForSelectionOfContainersInTemporaryStorage(
		Form.Object,
		TableName,
		ColumnsNames,
		Form.UUID,
		ShowWarehouse,
		ShowDate,
		ShowReceiptDate);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("AddressOfTheGoodsInTheTemporaryStorage", AddressOfTheGoodsInTheTemporaryStorage);
	ParametersStructure.Insert("ShowWarehouse", ShowWarehouse);
	ParametersStructure.Insert("ShowDate", ShowDate);
	ParametersStructure.Insert("ShowReceiptDate", ShowReceiptDate);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	OpenForm(
		"DataProcessor.SelectReusablePackage.Form.Form",
		ParametersStructure,
		Form,,,,
		New CallbackDescription("ChooseMultiTurnContainerSelectionOfContainersCompletion", ReusablePackageClient, AdditionalParameters));
	
EndProcedure

// The completion handler of the selection of reusable packaging.
//
// Parameters:
//  ReturnStructure - Structure, Undefined - necessary data to determine the status of multi-turn packaging selection.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure ChooseMultiTurnContainerSelectionOfContainersCompletion(ReturnStructure, AdditionalParameters) Export
	
	ThereIsStateOfFillingMultiTurnContainer = TMCommonUseClientServer.HasObjectAttribute(
		AdditionalParameters.Form.Object, "ReusablePackageFillingStatus");
	
	If ReturnStructure = Undefined Then
		
		If ThereIsStateOfFillingMultiTurnContainer Then
			If Not ValueIsFilled(AdditionalParameters.Form.Object.ReusablePackageFillingStatus) Then
				AdditionalParameters.Form.Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn");
			EndIf;
		EndIf;
		
		If AdditionalParameters.CallbackDescription <> Undefined Then
			RunCallback(AdditionalParameters.CallbackDescription, False);
		EndIf;
	
	Else
		
		If ThereIsStateOfFillingMultiTurnContainer Then
			If ReturnStructure.TaraIsPickedUp Then
				AdditionalParameters.Form.Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.FilledIn");
			Else
				AdditionalParameters.Form.Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn");
			EndIf;
		EndIf;
		
		If AdditionalParameters.CallbackDescription <> Undefined Then
			RunCallback(AdditionalParameters.CallbackDescription, ReturnStructure.TaraIsPickedUp);
		EndIf;
		
	EndIf;
	
EndProcedure

// Displays alerts to the user after adding a multi-turn container to the document.
//
Procedure NotifyUserAboutFillingMultiTurnContainers() Export
	
	ShowUserNotification(
		NStr("vi = 'Chọn bao bì luân chuyển';
			|ru = 'Подбор многооборотной тары';
			|en = 'Pick reusable packaging'; fa = 'انتخاب بسته‌بندی قابل استفاده مجدد';
			|it = 'Selezione imballaggi riutilizzabili';
			|pl = 'Wybór tary wielokrotnego użytku';
			|tr = 'Yeniden kullanılabilir ambalaj seçimi'"),
		,
		NStr("vi = 'Đã kết thúc chọn bao bì luân chuyển.';
			|ru = 'Подбор многооборотной тары завершен.';
			|en = 'Reusable packaging is picked.'; fa = 'Reusable packaging is picked.';
			|it = 'Selezione imballaggi riutilizzabili finito.';
			|pl = 'Wybór tary do wielokrotnego użytku jest zakończony.';
			|tr = 'Yeniden kullanılabilir ambalaj seçimi tamamlandı.'"));
	
EndProcedure

// Offers the user to add a multi-turn container to the document's products
// If the user agrees, it opens the multi-turn container selection form.
//
// Parameters:
// Form - ClientApplicationForm - The form from which multi-turn packaging is selected
// TableName - String - Name of the table with the products and packaging of the document
// ColumnsNames - String - Comma-separated names of columns in the table with products and packaging of the document.
// CallbackDescription - CallbackDescription - Notification description
// AskAQuestion - Boolean - Flag that determines whether to ask a question; if not set, it is calculated inside the procedure
//
Procedure OfferToPickUpMultiTurnContainer(Val Form,
	                                            Val TableName,
	                                            Val ColumnsNames,
	                                            CallbackDescription,
	                                            Val AskAQuestion = Undefined) Export
	
	State = Form.Object.ReusablePackageFillingStatus;
	StateFilled = ValueIsFilled(State);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("TableName", TableName);
	AdditionalParameters.Insert("ColumnsNames", ColumnsNames);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	
	If AskAQuestion = Undefined Then
		
		AskAQuestion = False;
		
		If Form.Object[TableName].Count() = 0 Or
			(StateFilled
				And (State = PredefinedValue("Enum.ReusablePackageFillingStates.NotOfferToFillIn")
					Or State = PredefinedValue("Enum.ReusablePackageFillingStates.FilledIn"))) Then
			
			AskAQuestion = False;
			
		ElsIf State = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn") Or
			Not StateFilled Then
			
			AskAQuestion = ReusablePackageServerCall.AskQuestionAboutFillingMultiTurnContainers(
				Form.Object,
				TableName,
				ColumnsNames);
			
		Else
			
			AskAQuestion = False;
			
		EndIf;
		
	EndIf;
	
	If Not AskAQuestion Then
		RunCallback(CallbackDescription, False);
		Return;
	EndIf;
	
	ResponseOptions = New ValueList();
	ResponseOptions.Add("Add", NStr("vi = 'Bổ sung';
									|ru = 'Дополнить';
									|en = 'Add'; fa = 'افزودن';
									|it = 'Aggiungere';
									|pl = 'Add';
									|tr = 'Doldur'"));
	ResponseOptions.Add("NotSupplement", NStr("vi = 'Chưa bổ sung';
												|ru = 'Не дополнять';
												|en = 'Do not add'; fa = 'افزوده نشود';
												|it = 'Non integrare';
												|pl = 'Nie dodawaj';
												|tr = 'Doldurma'"));
	
	ShowQueryBox(
		New CallbackDescription("OfferToPickUpMultiTurnContainerOrAddContainer", ReusablePackageClient, AdditionalParameters),
		NStr("vi = 'Thêm bao bì luân chuyển?';
			|ru = 'Дополнить многооборотной тарой?';
			|en = 'Add reusable packaging?'; fa = 'Add reusable packaging?';
			|it = 'Aggiungi l''imballaggio riutilizzabile?';
			|pl = 'Dodać tarę wielokrotnego użytku?';
			|tr = 'Yeniden kullanılabilir ambalajı doldur?'"),
		ResponseOptions);
	
EndProcedure

// The completion handler of the request for offer fill a reusable container.
//
// Parameters:
//  UserAnswer           - String - the answer to the question selected by the user.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OfferToPickUpMultiTurnContainerOrAddContainer(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotSupplement" Then
		
		AdditionalParameters.Form.Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.NotOfferToFillIn");
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	Else
		
		SelectReusablePackage(
			AdditionalParameters.Form,
			AdditionalParameters.TableName,
			AdditionalParameters.ColumnsNames,
			New CallbackDescription("OfferToPickUpMultiTurnContainerSelectionOfContainersCompletion", ReusablePackageClient, AdditionalParameters));
		
	EndIf;
	
EndProcedure

// The completion handler of the request for offer fill a reusable container.
//
// Parameters:
//  TaraIsPickedUp - Boolean - True if the container is selected.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OfferToPickUpMultiTurnContainerSelectionOfContainersCompletion(TaraIsPickedUp, AdditionalParameters) Export
	
	If TaraIsPickedUp Then
		AdditionalParameters.Form.Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.FilledIn");
	EndIf;
	
	RunCallback(AdditionalParameters.CallbackDescription, TaraIsPickedUp);
	
EndProcedure

// Resets the fill state of the multi-turn container in the document after changing the table part.
//
// Parameters:
// ReusablePackageFillingStatus - EnumRef.ReusablePackageFillingStates
//
Procedure UpdateFillingStateOfMultiTurnContainer(ReusablePackageFillingStatus) Export
	
	If ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.FilledIn") Then
		ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn");
	EndIf;
	
EndProcedure

#EndRegion
