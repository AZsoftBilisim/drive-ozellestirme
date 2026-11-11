
#Region FormEventHandlers

 &AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProcessPassedParameters(Parameters, Cancel);
	
	If Cancel Then
		Return;
	EndIf; 
	
	ConfigurationLanguages = DemoScenarios.ConfigurationLanguages();
	
	Items.SourceLanguage.ChoiceList.LoadValues(ConfigurationLanguages);
	Items.TargetLanguage.ChoiceList.LoadValues(ConfigurationLanguages);
	
	DemoScenarios.SetLanguageSettingInForm(ThisObject, "SourceLanguage", "TargetLanguage"); 
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

 &AtClient
 Procedure ToSetStatusOnChange(Item)
	 
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure MakeTransfer(Command)
	
	ClearMessages();
	
	If Not ResultOfFillCheck() Then
		
		Return;
		
	EndIf;
	
	Close(ReturnStructure());
	
EndProcedure

#EndRegion 

#Region Private

&AtServer
Procedure ProcessPassedParameters(Var_Parameters, Cancel)
	
	TextOfMessageIsNotAvailableForTranslation = NStr("vi = 'Chưa chuyển đối tượng nào để dịch';
													|ru = 'Не передано ни одного объекта для перевода';
													|en = 'No object is passed for translation'; fa = 'No object is passed for translation';
													|it = 'Не передано ни одного объекта для перевода';
													|pl = 'No object is passed for translation';
													|tr = 'Çeviri için herhangi bir nesne aktarılmadı'");
	
	If  Var_Parameters.TranslatedObjects.Count() = 0 Then
		
		
	EndIf;
	
	For Each ListItem In Var_Parameters.TranslatedObjects Do
		
		If TypeOf(ListItem.Value) = Type("CatalogRef.DemoScenarios") Then
			
			TranslatedScripts.Add(ListItem.Value);
			
		ElsIf TypeOf(ListItem.Value) = Type("CatalogRef.Glossary") Then
			
			TranslatedGlossaries.Add(ListItem.Value); 
			
		EndIf;
		
	EndDo;
	
	If TranslatedScripts.Count() = 0 
		And TranslatedGlossaries.Count() = 0 Then
		
		Common.MessageToUser(TextOfMessageIsNotAvailableForTranslation);
		Cancel = True;
		
		Return;
		
	EndIf;

EndProcedure 

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Items = Form.Items;
	
	Items.SetStatus_.Enabled = Form.ToSetStatus;
	
EndProcedure

&AtClient
Function ResultOfFillCheck()
	
	FilledIn_Correctly = True;
	
	If Not ValueIsFilled(SourceLanguage) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra ngôn ngữ mà từ đó sẽ thực hiện dịch';
										|ru = 'Не указан язык, с которого будет выполняться перевод';
										|en = 'A source language is not specified'; fa = 'A source language is not specified';
										|it = 'Не указан язык, с которого будет выполняться перевод';
										|pl = 'A source language is not specified';
										|tr = 'Çevirinin hangi dilden yapılacağı belirtilmedi'"),,"SourceLanguage");
		FilledIn_Correctly = False;
	EndIf; 
	
	If Not ValueIsFilled(TargetLanguage) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra ngôn ngữ mà sẽ thực hiện dịch sang ngôn ngữ đó';
										|ru = 'Не указан язык, на который будет выполняться перевод';
										|en = 'A target language is not specified'; fa = 'A target language is not specified';
										|it = 'Не указан язык, на который будет выполняться перевод';
										|pl = 'A target language is not specified';
										|tr = 'Çevirinin hangi dile yapılacağı belirtilmedi'"),,"TargetLanguage");
		FilledIn_Correctly = False;
	EndIf;
	
	If FilledIn_Correctly 
		And SourceLanguage = TargetLanguage Then
		
		CommonClient.MessageToUser(NStr("vi = 'Ngôn ngữ nguồn và ngôn ngữ đích giống nhau';
										|ru = 'Исходный и целевой языки одинаковые';
										|en = 'The source and target languages are the same'; fa = 'The source and target languages are the same';
										|it = 'Исходный и целевой языки одинаковые';
										|pl = 'The source and target languages are the same';
										|tr = 'Kaynak ve hedef diller aynı'"),,"TargetLanguage");
		FilledIn_Correctly = False
		
	EndIf; 
	
	If ToSetStatus 
		And Not ValueIsFilled(SetStatus_) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra trạng thái đã thiết lập';
										|ru = 'Не указан устанавливаемый статус';
										|en = 'The status to set is not specified'; fa = 'The status to set is not specified';
										|it = 'Не указан устанавливаемый статус';
										|pl = 'The status to set is not specified';
										|tr = 'Yapılandırılan durum belirtilmedi'"),,"SetStatus_");
		FilledIn_Correctly = False;
		
	EndIf;
	
	Return FilledIn_Correctly;

EndFunction

&AtClient
Function ReturnStructure()

	ReturnStructure = New Structure;
	
	ReturnStructure.Insert("SourceLanguage",                      SourceLanguage);
	ReturnStructure.Insert("TargetLanguage",                       TargetLanguage);
	ReturnStructure.Insert("ToSetStatus",               ToSetStatus);
	ReturnStructure.Insert("SetStatus_",             SetStatus_);
	ReturnStructure.Insert("OverwriteExistingTranslation", OverwriteExistingTranslation);
	ReturnStructure.Insert("TranslatedGlossaries",              TranslatedGlossaries);
	ReturnStructure.Insert("TranslatedScripts",               TranslatedScripts);
	
	Return ReturnStructure;

EndFunction

#EndRegion



