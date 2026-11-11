#Region Variables

&AtClient
Var ResponseBeforeWrite;

#EndRegion

#Region FormsEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then     
		Return;
	EndIf;                        
	
	CurrentUser = InfoBaseUsers.CurrentUser();
	
	If CommonCEL.ThisIsMobilePlatform() Then
		CommonCEL.PrepareControl(Items.Description);
		CommonCEL.PrepareControl(Items.Code);
		CommonCEL.PrepareControl(Items.ComputerName);
	EndIf;                        
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If IsBlankString(Object.Code) Then
		Object.Code = EquipmentManagerClient.ClientIDForWorkplace();
	EndIf;
	
	EquipmentManagerClientServer.FillInWorkplaceName(Object, CurrentUser);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not CheckingUniquenessByClientID(Object.Ref, Object.Code) Then
		Cancel = True;
		Text = NStr("vi = 'Lỗi lưu lại chỗ làm việc.
					|Đã tồn tại chỗ làm việc với tên định danh Client như vậy.';
					|ru = 'Ошибка сохранение рабочего места.
					|Рабочее место с таким идентификатором клиента уже существует.';
					|en = 'An error occurred when saving the workplace.
					|The workplace with such client ID already exists.'; fa = 'An error occurred when saving the workplace.
					|The workplace with such client ID already exists.';
					|it = 'Errore durante il salvataggio del posto di lavoro.
					|Un posto di lavoro con questo ID esiste già.';
					|pl = 'Błąd zapisu miejsca pracy.
					|Miejsce pracy z takim identyfikatorem klienta już istnieje.';
					|tr = 'Çalışma alanı kaydedilemedi.
					|Bu müşteri kimliğine sahip çalışma alanı zaten var.'");
		CommonCELClient.MessageToUser(Text);
		Return;
	EndIf;
	
	If Not CheckingUniquenessByName(Object.Ref, Object.Description)Then
		If ResponseBeforeWrite <> True Then
			Cancel = True;
			Text = NStr("vi = 'Đã chỉ định tên chỗ làm việc không đơn trị.
						|Có thể là sau này điều đó sẽ làm chậm quá trình định danh và chọn chỗ làm việc.
						|Nên chỉ định tên chỗ làm việc đơn trị.
						|Tiếp tục lưu lại với tên đã chỉ định?';
						|ru = 'Указано неуникальное наименование рабочего места.
						|Возможно в дальнейшем это затруднит идентификацию и выбор рабочего места.
						|Рекомендуется указывать уникальное наименование рабочих мест.
						|Продолжить сохранение с указанным наименованием?';
						|en = 'The workplace name is not unique.
						|It might cause identification issues.
						|Specify a unique name of the workplace.
						|Do you want to continue with the specified name anyway?'; fa = 'The workplace name is not unique.
						|It might cause identification issues.
						|Specify a unique name of the workplace.
						|Do you want to continue with the specified name anyway?';
						|it = 'È stato indicato un nome non univoco per il luogo di lavoro.
						|In futuro ciò potrebbe complicare l''identificazione e la selezione del luogo di lavoro
						|.Si consiglia di indicare nomi univoci per i luoghi di lavoro.
						|Continuare il salvataggio con il nome specificato?';
						|pl = 'Wskazana nazwa miejsca pracy nie jest unikalna.
						|Może to w przyszłości utrudnić identyfikację i wybór miejsca pracy.
						|Zaleca się wskazywanie unikalnej nazwy miejsc pracy.
						|Kontynuować zapis ze wskazaną nazwą?';
						|tr = 'Benzersiz olmayan çalışma alanı tanımı belirtildi.
						|Bu durum, daha sonra bir çalışma alanı tanımlamayı ve seçmeyi zorlaştırır.
						|Benzersiz bir çalışma alanı tanımı belirtmeniz önerilir.
						|Belirtilen tanımla kaydetmeye devam edilsin mi?'");
			Notification = New CallbackDescription("BeforeWriteCompletion", ThisObject);
			ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeWriteCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ResponseBeforeWrite = True;
		Write();
	EndIf;  
	
EndProcedure 
   
&AtClient
Procedure AfterWrite(WriteParameters)
	
	If Object.Code = EquipmentManagerClient.ClientIDForWorkplace() Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	EquipmentManagerClientServer.FillInWorkplaceName(Object, CurrentUser);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function CheckingUniquenessByName(Ref, Description)
	
	Result = True;
	
	If Not IsBlankString(Description) Then
		Query = New Query("
		|SELECT
		|    1
		|FROM
		|    Catalog.Workplaces AS Workplaces
		|WHERE
		|    Workplaces.Description = &Description
		|    AND Workplaces.Ref <> &Ref
		|");
		Query.SetParameter("Description", Description);
		Query.SetParameter("Ref"      , Ref);
		Result = Query.Execute().IsEmpty();
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function CheckingUniquenessByClientID(Ref, ClientID)
	
	Result = True;
	
	If Not IsBlankString(ClientID) Then
		Query = New Query("
		|SELECT
		|    1
		|FROM
		|    Catalog.Workplaces AS Workplaces
		|WHERE
		|    Workplaces.Code = &Code
		|    AND Workplaces.Ref <> &Ref
		|");
		Query.SetParameter("Code"    , ClientID);
		Query.SetParameter("Ref" , Ref);
		Result = Query.Execute().IsEmpty();
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion