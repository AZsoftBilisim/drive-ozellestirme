#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public 

// This function generates an HTML notification text for a budget task.
//
// Parameters:
//  NotificationKind - EnumRef.BudgetTasksNotificationKinds - Type of notification for budget issues.
//  Parameters - Structure - Email Parameters:
//   *Performer - CatalogRef.Users - The performer parameter.
//   *BudgetTask - TaskRef.BudgetTask - Budget task parameter.
//  ArtistLanguageCode - String - Code of the language in which the letter will be written to the performer of the budget task. 
//
// Returns:
//  String - text in HTML format.
//
Function GetEmailParametersUsingTemplate(NotificationKind, Parameters, ArtistLanguageCode) Export
	
	Result = New Structure;
	Result.Insert("Subject",      Undefined);
	Result.Insert("Body",      Undefined);
	Result.Insert("TextType", Enums.EmailTextTypes.HTML);
	Result.Insert("Encoding", "UTF-8");
	Result.Insert("Importance",  Undefined);
	
	If NotificationKind = Enums.BudgetTasksNotificationKinds.NewTaskWasReceived Then
		Result.Subject = NStr("vi = 'Một thử thách mới đã đến';
								|ru = 'Поступила новая задача';
								|en = 'New task was received'; fa = 'وظیفه جدید دریافت شد';
								|it = 'Arrivato un nuovo task';
								|pl = 'Otrzymano nowe zadanie';
								|tr = 'Yeni görev alındı'", ArtistLanguageCode);
		Result.Importance = InternetMailMessageImportance.Normal;
		
	ElsIf NotificationKind = Enums.BudgetTasksNotificationKinds.TaskDeadlineIsUpcoming Then
		Result.Subject = NStr("vi = 'Thời hạn hoàn thành nhiệm vụ sắp kết thúc.';
								|ru = 'Подходит к концу срок исполнения задачи';
								|en = 'Task deadline is coming to an end'; fa = 'Task deadline is coming to an end';
								|it = 'Giunge la scadenza del termine di esecuzione del task';
								|pl = 'Termin wykonania zadania dobiega końca';
								|tr = 'Görev tamamlama süresinin sonuna geliyor'", ArtistLanguageCode);
		Result.Importance = InternetMailMessageImportance.High;
		
	ElsIf NotificationKind = Enums.BudgetTasksNotificationKinds.OverdueTask Then
		Result.Subject = NStr("vi = 'Nhiệm vụ đã hết hạn';
								|ru = 'Просрочено исполнение задачи';
								|en = 'Overdue task execution'; fa = 'Overdue task execution';
								|it = 'Termine di esecuzione del task è scaduto';
								|pl = 'Wygasł termin realizacji zadania';
								|tr = 'Vadesi geçmiş görevler'", ArtistLanguageCode);
		Result.Importance = InternetMailMessageImportance.Highest;
		
	EndIf;
	
	AddEmailBody(NotificationKind, Parameters, Result, ArtistLanguageCode);
	
	Return Result;
	
EndFunction

#EndRegion


#Region Private

Procedure AddEmailBody(NotificationKind, Parameters, Result, ArtistLanguageCode)
	
	Attributes = New Structure("Gender", "Individual.Gender");
	Attributes = Common.ObjectAttributesValues(Parameters.Performer, Attributes);
	
	Parameters.Insert("SupportRequest", NStr("vi = 'Xin chào';
											|ru = 'Здравствуйте';
											|en = 'Hello'; fa = 'Hello';
											|it = 'Buongiorno';
											|pl = 'Hello';
											|tr = 'Merhaba'", ArtistLanguageCode));
	If Attributes.Gender = Enums.GenderPersons.Masculine Then
		Parameters.SupportRequest = NStr("vi = 'Trân trọng';
										|ru = 'Уважаемый';
										|en = 'Dear'; fa = 'گرامی';
										|it = 'Egregio';
										|pl = 'Szanowny';
										|tr = 'Saygıdeğer'", ArtistLanguageCode);
		
	ElsIf Attributes.Gender = Enums.GenderPersons.Feminine Then
		Parameters.SupportRequest = NStr("vi = 'Trân trọng';
										|ru = 'Уважаемый';
										|en = 'Dear'; fa = 'گرامی';
										|it = 'Egregio';
										|pl = 'Szanowny';
										|tr = 'Saygıdeğer'", ArtistLanguageCode);
		
	EndIf;
	
	LocalInfobasePublishingURL = 
		Common.LocalInfobasePublishingURL();
	If Not IsBlankString(LocalInfobasePublishingURL) Then
		HyperlinkAddress =
			LocalInfobasePublishingURL + "#" +  GetURL(Parameters.BudgetTask);
		LinkToTask = NStr("vi = 'Để xem tác vụ, hãy theo liên kết: <a href=""%1""> %2 </a>';
							|ru = 'Для просмотра задачи перейдите по ссылке: <a href=""%1"">%2</a>';
							|en = 'To view the task, click: <a href=""%1"">%2</a>'; fa = 'To view the task, click: <a href=""%1"">%2</a>';
							|it = 'Для просмотра задачи перейдите по ссылке: <a href=""%1"">%2</a>';
							|pl = 'To view the task, click: <a href=""%1"">%2</a>';
							|tr = 'Görevi görüntülemek için bu bağlantıya geçin: <a href=""%1"">%2</a>'", ArtistLanguageCode);
		LinkToTask = StringFunctionsClientServer.SubstituteParametersToString(LinkToTask, HyperlinkAddress, HyperlinkAddress);
		
	Else
		IBLabelName = NStr("vi = 'Khởi chạy CSTT';
							|ru = 'Запустить информационную базу';
							|en = 'Start infobase'; fa = 'Start infobase';
							|it = 'Avviare il database';
							|pl = 'Uruchom bazę informacyjną';
							|tr = 'Veri tabanını başlat'", ArtistLanguageCode);
		Result.Insert("IBLabelName", IBLabelName);
		LinkToTask = 
			NStr("vi = 'Để mở CSTT, bạn có thể sử dụng tệp đính kèm ""%1"".';
				|ru = 'Для того чтобы открыть информационную базу Вы можете воспользоваться вложенным файлом ""%1"".';
				|en = 'To open the infobase, you can use the ""%1"" attached file.'; fa = 'To open the infobase, you can use the ""%1"" attached file.';
				|it = 'Per aprire il database potete utilizzare il file allegato ""%1"".';
				|pl = 'W celu otwarcia bazy informacyjnej możesz użyć załączonego pliku ""%1"".';
				|tr = 'Infobase''i açmak için ekteki ""%1"" dosyasını kullanabilirsiniz.'", ArtistLanguageCode);
		LinkToTask = StringFunctionsClientServer.SubstituteParametersToString(LinkToTask, IBLabelName);
	
	EndIf;
	
	Parameters.Insert("LinkToTask", LinkToTask);
	
	If NotificationKind = Enums.BudgetTasksNotificationKinds.NewTaskWasReceived Then
		TextTemplateTemplate = GetTemplate("HTMLEmailTemplateReceived");
	ElsIf NotificationKind = Enums.BudgetTasksNotificationKinds.TaskDeadlineIsUpcoming Then
		TextTemplateTemplate = GetTemplate("HTMLEmailTemplateDeadlineIsUpcoming");
	Else
		TextTemplateTemplate = GetTemplate("HTMLEmailTemplateOverdue");
	EndIf;
	TextTemplateTemplate.TemplateLanguageCode = ArtistLanguageCode;
	
	HTMLText = TextTemplateTemplate.GetText();
	
	HTMLText = FillTemplateWithSubstitutionValues(HTMLText, Parameters, ArtistLanguageCode);
	
	Result.Body = HTMLText;
	
EndProcedure

Function FillTemplateWithSubstitutionValues(TextTemplate1, SubstitutionValues, ArtistLanguageCode)
	
	FormatStringCode = StrTemplate(NStr("vi = 'Л=%1; ДЛФ=DD';
										|ru = 'Л=%1; ДЛФ=DD';
										|en = 'L=%1; DLF=DD'; fa = 'L=%1; DLF=DD';
										|it = 'L=%1; DLF=DD';
										|pl = 'L=%1; DLF=DD';
										|tr = 'L=%1;DLF=DD'", ArtistLanguageCode), "ru_RU");
	Result = TextTemplate1;
	Result = StrReplace(Result, "[SupportRequest]", SubstitutionValues.SupportRequest);
	Result = StrReplace(Result, "[PerformerPresentation]", SubstitutionValues.PerformerPresentation);
	Result = StrReplace(Result, "[TaskDescription]", SubstitutionValues.TaskDescription);
	Result = StrReplace(Result, "[TaskDueDate]", Format(SubstitutionValues.TaskDueDate, FormatStringCode));
	Result = StrReplace(Result, "[LinkToTask]", SubstitutionValues.LinkToTask);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf