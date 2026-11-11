#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	NewPhone = Parameters.NewPhone;
	Certificate = Parameters.Certificate;
		
	ApplicationID = String(New UUID);
	
	FillInVariablesForPhoneVerification(ThisObject);
	If Parameters.Property("CheckID") Then
		ConfirmPhoneNumberForPasswords.CheckID = Parameters.CheckID;
		ConfirmPhoneNumberForPasswords.ConfirmationCompleted = ValueIsFilled(ConfirmPhoneNumberForPasswords.CheckID);
		ConfirmPhoneNumberForPasswords.ValueEntered = ValueIsFilled(ConfirmPhoneNumberForPasswords.CheckID);
	EndIf;

	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.NewPhone.UpdateEditText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NewPhoneOnChange(Item)
	
	NewPhoneEditTextChange(Item, Item.EditText, True);
	
EndProcedure

&AtClient
Procedure NewPhoneEditTextChange(Item, Text, StandardProcessing)
	
	Presentation = DigitalSignatureSaaSClientServer.GetPhonePresentation(Text);
	NewPhone = Presentation;
	
	ConfirmPhoneNumberForPasswords.ValueEntered = ValueIsFilled(Presentation);
	If Not ValueIsFilled(Presentation) Then
		NewPhone = Text;
	EndIf;
	
	DetachIdleHandler("Attachable_HandlerCountdown");
	DetachIdleHandler("Attachable_UpdateNewPhone");
	AttachIdleHandler("Attachable_UpdateNewPhone", 1, True);
	
EndProcedure

&AtClient
Procedure ConfirmationCodeOnChange(Item)
	
	ConfirmationCodeEditTextChange(Item, Item.EditText, True);
	
EndProcedure

&AtClient
Procedure ConfirmationCodeEditTextChange(Item, Text, StandardProcessing)
	
	If StrLen(TrimAll(Text)) = 6 Then
		ConfirmationCode = TrimAll(Text);
		AttachIdleHandler("Attachable_CheckConfirmationCode", 0.5, True); 
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfirmPhoneNumber(Command)
	
	SendConfirmationCode();

EndProcedure

&AtClient
Procedure CancelPhoneNumberConfirmationClick(Item)
	
	ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False);
	NewPhone = Undefined;
	Timer = 0;
	DetachIdleHandler("Attachable_HandlerCountdown");
	AttachIdleHandler("Attachable_UpdateTextOfNewPhoneField", 0.1, True);
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure ResendCode(Command)
	
	SendConfirmationCode();
	
EndProcedure

&AtClient
Procedure Step1LabelURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;	
	If Var_URL = "#PrintStatement" And VerifyPhoneVerification() Then
		Result = GetTabularDocumentOnServer(
			ApplicationID, ConfirmPhoneNumberForPasswords.CheckID, 
			CryptographyServiceInternalClient.Id(Certificate));
		If Result.Completed2 Then
			ApplicationIsPrinted = True;
			PrintFormID = "ApplicationForChangeOfPhoneNumber";
			PrintFormName = NStr("vi = 'Yêu cầu thay đổi số thuê bao di động';
								|ru = 'Заявление на смену абонентского номера подвижной (мобильной) связи';
								|en = 'Application for changing the cell phone number'; fa = 'Application for changing the cell phone number';
								|it = 'Domanda di modifica del numero di abbonamento della telefonia mobile';
								|pl = 'Wniosek o zmianę numeru abonenta sieci mobilnej (komórkowej)';
								|tr = 'Mobil (cep telefonu) abone numarasını değiştirme başvurusu'");
			
			If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
				ModuleNamePrintManagementClient = "PrintManagementClient"; 
				ModulePrintManagerClient = CommonClient.CommonModule(ModuleNamePrintManagementClient);
				
				PrintFormsCollection = ModulePrintManagerClient.NewPrintFormsCollection(PrintFormID);
				PrintForm = ModulePrintManagerClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
				PrintForm.TemplateSynonym = PrintFormName;
				PrintForm.SpreadsheetDocument = Result.File;
				PrintForm.PrintFormFileName = PrintFormName;
				
				ObjectsAreas = New ValueList;
				ModulePrintManagerClient.PrintDocuments(PrintFormsCollection, ObjectsAreas);
			Else
				Result.File.Show(PrintFormName);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationFileClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not VerifyPhoneVerification() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("FileStatementClickingAfterPlacingFile", ThisObject);
	BeginPutFile(Notification,,, True, UUID);
	
EndProcedure

&AtClient
Procedure FileStatementClickingAfterPlacingFile(Result, Address, SelectedFileName, IncomingContext) Export
	
	If Result Then
		File = New File(SelectedFileName);
		ApplicationFile = File.Name;
		ApplicationFilePath = Address;
	EndIf;
	
EndProcedure

&AtClient
Procedure SendApplication(Command)
	
	If Not VerifyPhoneVerification() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ApplicationFilePath) Then
		MessageText = NStr("vi = 'Hãy chọn tệp yêu cầu';
							|ru = 'Выберите файл заявления';
							|en = 'Select application file'; fa = 'Select application file';
							|it = 'Selezionare file della domanda';
							|pl = 'Wybierz plik wniosku';
							|tr = 'Başvuru dosyasını seçin'");
		CommonClient.MessageToUser(MessageText,, "ApplicationFile");
		Return;
	EndIf;
	
	TheNotificationIsAsFollows = New CallbackDescription("UserSelectionResult", ThisObject);
	ListOfCommands = New ValueList;
	ListOfCommands.Add(SendApplicationCommand(), NStr("vi = 'Gửi yêu cầu';
														|ru = 'Отправить заявление';
														|en = 'Send application'; fa = 'ارسال درخواست';
														|it = 'Inviare l''applicazione';
														|pl = 'Wyślij wniosek';
														|tr = 'Başvuruyu gönder'"), True);
	ListOfCommands.Add(CancelCommand(),  NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
	
	QueryText = StringFunctionsClient.FormattedString(
		NStr("vi = 'Chú ý, cần xác thực tài liệu scan đính kèm bằng:
			|1. Con dấu của doanh nghiệp bạn và chữ ký của người sở hữu chứng thư.
			|2. Con dấu của doanh nghiệp dịch vụ và chữ ký của người chịu trách nhiệm.
			|
			|<b>Cả hai cách xác thực trên là bắt buộc, nếu không yêu cầu sẽ bị từ chối. </b>
			|';
			|ru = 'Обратите внимание, прилагаемый сканированный документ должен быть заверен:
			|1. Печатью вашей организации и подписью владельца сертификата.
			|2. Печатью обслуживающей организации и подписью ее уполномоченного сотрудника.
			|
			|<b>Оба заверения обязательны, иначе заявление будет отклонено. </b>
			|';
			|en = 'Note that the attached scanned document must be certified with:
			|1. Seal of your company and signature of the certificate owner.
			|2. Seal of the service provider and signature of its authorized employee.
			|
			|<b>Both certifications are required, otherwise the application will be rejected. </b>
			|'; fa = 'Note that the attached scanned document must be certified with:
			|1. Seal of your company and signature of the certificate owner.
			|2. Seal of the service provider and signature of its authorized employee.
			|
			|<b>Both certifications are required, otherwise the application will be rejected. </b>
			|';
			|it = 'Обратите внимание, прилагаемый сканированный документ должен быть заверен:
			|1. Печатью вашей организации и подписью владельца сертификата.
			|2. Печатью обслуживающей организации и подписью ее уполномоченного сотрудника.
			|
			|<b>Оба заверения обязательны, иначе заявление будет отклонено. </b>
			|';
			|pl = 'Note that the attached scanned document must be certified with:
			|1. Seal of your company and signature of the certificate owner.
			|2. Seal of the service provider and signature of its authorized employee.
			|
			|<b>Both certifications are required, otherwise the application will be rejected. </b>
			|';
			|tr = 'Lütfen ekteki taranmış belgenin onaylı olması gerektiğini unutmayın:
			|1. İş yerinizin mührü ve sertifika sahibinin imzası ile.
			|2. Hizmet veren iş yerinin mührü ve yetkili memurunun imzası ile.
			|
			|<b>Her iki onay da zorunludur, aksi takdirde başvuru reddedilecektir.</b>
			|'"));

	FormParameters = New Structure;
	FormParameters.Insert("ListOfCommands", ListOfCommands);
	FormParameters.Insert("QueryText", QueryText);
	FormParameters.Insert("Title",  NStr("vi = 'Hãy chắc chắn rằng, yêu cầu đã được xác thực';
										|ru = 'Убедитесь, что заявление заверено верно';
										|en = 'Make sure the application is certified correctly'; fa = 'Make sure the application is certified correctly';
										|it = 'Assicurarsi che la domanda è compilata correttamente';
										|pl = 'Upewnij się, że wniosek jest poświadczony poprawnie';
										|tr = 'Başvurunun doğru şekilde onaylandığından emin olun'"));
	FormParameters.Insert("ConfirmationHeader",  NStr("vi = 'Tôi xác nhận rằng, yêu cầu đã được xác thực bởi hai doanh nghiệp';
														|ru = 'Подтверждаю, что заявление заверено обеими организациями';
														|en = 'I confirm that the application is certified by both companies'; fa = 'I confirm that the application is certified by both companies';
														|it = 'Confermo che la domanda è asseverata da entrambe le aziende';
														|pl = 'Potwierdzam, że wniosek jest zakończony przez obie firmy';
														|tr = 'Başvurunun her iki iş yeri tarafından da onaylandığını teyit ederim'"));
	
	OpenForm("CommonForm.ConfirmationOfPhoneChange", FormParameters, ThisObject, , , , TheNotificationIsAsFollows);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UserSelectionResult(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult = SendApplicationCommand() Then
		File = New Structure("Name,Address", ApplicationFile, ApplicationFilePath);
		Result = PreparationOfApplication(File); 
		If Result.Completed2 Then
			ApplicationSent = True;
			FormControl(ThisObject);
		Else
			CommonClient.MessageToUser(Result.ErrorDescription); 
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function SendApplicationCommand()
	
	Return "SendApplication";
	
EndFunction

&AtClient
Function CancelCommand()
	
	Return "Cancel";
	
EndFunction

&AtClient
Procedure SendConfirmationCode()
	
	DetachIdleHandler("Attachable_UpdateNewPhone");
	ClearMessages();
	ConfirmationCode = Undefined;
	
	Result = CheckNumberOnServer(NewPhone, ConfirmPhoneNumberForPasswords.CheckID);
	If Result.Completed2 Then
		Timer = Result.DelayBeforeResending;
		ConfirmPhoneNumberForPasswords.CheckID = Result.Id;
		StartCountdown();
		ConfirmPhoneNumberForPasswords.CheckInProgress = True;
		ConfirmPhoneNumberForPasswords.CodeSent = True;
		
		AttachIdleHandler("Attachable_ActivateConfirmationCodeField", 0.1, True);	
	Else
		CommonClient.MessageToUser(Result.ErrorDescription,, "NewPhone");
	EndIf;
	FormControl(ThisObject);
	
EndProcedure

&AtServerNoContext
Function CheckNumberOnServer(Phone, Id)
	
	Return CryptographyServiceManager.GetPhoneVerificationCode(Phone, Id);
	
EndFunction

&AtClient
Procedure Attachable_ActivateConfirmationCodeField()
	
	CurrentItem = Items.ConfirmationCode;
	
EndProcedure

&AtClient
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer = Timer - 1;
	If Timer >= 0 Then
		CountdownLabel = StrTemplate(NStr("vi = 'Có thể sẽ hỏi lại mã sau %1 giây.';
											|ru = 'Запросить код повторно можно будет через %1 сек.';
											|en = 'You can request the code again in %1 sec.'; fa = 'You can request the code again in %1 sec.';
											|it = 'È possibile richiedere ancora il codice tra %1 secondi';
											|pl = 'Ponowna prośba o wysłanie kodu będzie możliwa przez %1 sek.';
											|tr = '%1 saniye içerisinde kodu tekrar isteyebilirsiniz.'"), Timer);
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		CountdownLabel = "";
		ConfirmPhoneNumberForPasswords.CodeSent = False;
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

// Returns:
//  Boolean - a sign of confirmation.
&AtClient
Function VerifyPhoneVerification()
	
	If Not ConfirmPhoneNumberForPasswords.ConfirmationCompleted Then
		MessageText = NStr("vi = 'Ban đầu, cần xác nhận số điện thoại mới';
							|ru = 'Сначала необходимо подтвердить новый номер телефона';
							|en = 'Confirm a new phone number first'; fa = 'Confirm a new phone number first';
							|it = 'All''inizio è necessario confermare il nuovo numero di telefono';
							|pl = 'Najpierw należy potwierdzić nowy numer telefonu';
							|tr = 'Öncelikle yeni telefon numarasını onaylamanız gerekir'");
		CommonClient.MessageToUser(MessageText,, "NewPhone");		
	EndIf;
	
	Return ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
	
EndFunction

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.PhoneNumberConfirmedPicture.Visible = Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
	Items.ConfirmPhoneNumber.Visible = 
		Form.ConfirmPhoneNumberForPasswords.ValueEntered 
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted 
		And Not Form.ConfirmPhoneNumberForPasswords.CheckInProgress;
	Items.NewPhone.ReadOnly = ValueIsFilled(Form.ConfirmPhoneNumberForPasswords.CheckID);
	Items.ConfirmationCodeGroup.Visible = 
		Form.ConfirmPhoneNumberForPasswords.CheckInProgress 
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
		
	Items.ResendCode.Visible = Not Form.ConfirmPhoneNumberForPasswords.CodeSent;
	Items.CountdownLabel.Visible = Form.ConfirmPhoneNumberForPasswords.CodeSent;
	
	Form.ApplicationFile = NStr("vi = 'Chọn';
								|ru = 'Выбрать';
								|en = 'Select'; fa = 'انتخاب';
								|it = 'Selezionare';
								|pl = 'Select';
								|tr = 'Seç'");
	
	Items.InstructionGroup_.Visible = Not Form.ApplicationSent;
	Items.Information.Visible = Form.ApplicationSent;
	Items.Information.Title = StrTemplate(NStr("vi = 'Đã tiếp nhận yêu cầu để xem xét.
                                                    |Sau khi yêu cầu được xem xét, sẽ có một SMS gửi đến số điện thoại %1';
                                                    |ru = 'Заявление принято к рассмотрению.
                                                    |По результатам рассмотрения заявления будет отправлено SMS на номер %1';
                                                    |en = 'Your request is under review.
                                                    |We''ll send you a text with the status to %1'; fa = 'درخواست شما در حال بررسی است.
                                                    |پیامکی حاوی وضعیت به %1 برای شما ارسال خواهیم کرد';
                                                    |it = 'Domanda accettata per valutazione. 
                                                    | In base ai risultati di valutazione della domanda verrà inviato un SMS al numero %1';
                                                    |pl = 'Wniosek został przyjęty do rozpatrzenia.
                                                    |Na podstawie wyników rozpatrzenia wniosku będzie wysłana wiadomość SMS na numer %1';
                                                    |tr = 'Başvuru değerlendirilmek üzere kabul edildi.
                                                    |Değerlendirmenin sonucuna göre, %1 numarasına SMS gönderilecektir '"), Form.NewPhone);
													
EndProcedure

&AtServerNoContext
Function GetTabularDocumentOnServer(ApplicationID, CheckID, CertificateID)
	
	Result = CryptographyServiceManager.PrintStatement(ApplicationID, CheckID, CertificateID);
	If Not Result.Completed2 Then
		Common.MessageToUser(Result.ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function SendApplicationAtServer(ApplicationID, ApplicationFile)
	
	Result = CryptographyServiceManager.SendApplication(ApplicationID, ApplicationFile);
	If Not Result.Completed2 Then
		Common.MessageToUser(Result.ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function PreparationOfApplication(File)
	
	Result	= New Structure();
	Result.Insert("Completed2", True);
	
	If Not ApplicationIsPrinted Then
		Result = GetTabularDocumentOnServer(
			ApplicationID, ConfirmPhoneNumberForPasswords.CheckID, 
			CryptographyServiceInternal.Id(Certificate));
	EndIf;
	
	If Result.Completed2 Then
		Result = SendApplicationAtServer(ApplicationID, File);
	EndIf;	
	
	Return Result;
	
EndFunction

&AtClient
Procedure Attachable_CheckConfirmationCode()
	
	ClearMessages();
	
	ConfirmationCode = TrimAll(ConfirmationCode);
	If StrLen(ConfirmationCode) = 6 Then
		Result = Undefined;
		
		If ConfirmPhoneNumberForPasswords.CheckInProgress Then
			Result = CheckPhoneByCodeOnServer(
				ConfirmPhoneNumberForPasswords.CheckID, ConfirmationCode);
			If Result.Completed2 Then
				ConfirmPhoneNumberForPasswords.CheckInProgress = False;
				ConfirmPhoneNumberForPasswords.ConfirmationCompleted = True;				
			EndIf;
		EndIf;
		
		If Result <> Undefined Then
			If Result.Completed2 Then
				DetachIdleHandler("Attachable_HandlerCountdown");
				FormControl(ThisObject);
			Else
				CommonClient.MessageToUser(Result.ErrorDescription,, "ConfirmationCode");
			EndIf;
		EndIf;	
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckPhoneByCodeOnServer(Id, ConfirmationCode) 
	
	Return CryptographyServiceManager.CheckPhoneNumberByCode(Id, ConfirmationCode);
	
EndFunction

&AtClient
Procedure Attachable_UpdateNewPhone()
	
	Items.ConfirmPhoneNumber.Visible = ConfirmPhoneNumberForPasswords.ValueEntered;
	If ConfirmPhoneNumberForPasswords.ValueEntered Then
		Items.NewPhone.UpdateEditText();
		DetachIdleHandler("Attachable_ActivateCheckNumberButton");
		AttachIdleHandler("Attachable_ActivateCheckNumberButton", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateTextOfNewPhoneField()
	
	Items.NewPhone.UpdateEditText();
	
EndProcedure

&AtClient
Procedure Attachable_ActivateCheckNumberButton()
	
	CurrentItem = Items.ConfirmPhoneNumber;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInVariablesForPhoneVerification(Form)
	
	Form.ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False);
	
EndProcedure

&AtClientAtServerNoContext
Function ConfirmPhoneNumberForPasswords(ValueEntered, CheckInProgress, CheckID, ConfirmationCompleted, CodeSent)
	
	ConfirmPhoneNumberForPasswords = New Structure;
	
	ConfirmPhoneNumberForPasswords.Insert("ValueEntered", ValueEntered);
	ConfirmPhoneNumberForPasswords.Insert("CheckInProgress", CheckInProgress);
	ConfirmPhoneNumberForPasswords.Insert("CheckID", CheckID);
	ConfirmPhoneNumberForPasswords.Insert("ConfirmationCompleted", ConfirmationCompleted);
	ConfirmPhoneNumberForPasswords.Insert("CodeSent", CodeSent);
	
	Return ConfirmPhoneNumberForPasswords;
	
EndFunction

#EndRegion