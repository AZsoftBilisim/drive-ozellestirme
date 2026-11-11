
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeTheForm();
	
	SelectionListsClientServer.Load("StoryIsGlobalThatWeAreChangingDemoScenarios", Items.SearchText.ChoiceList);
	SelectionListsClientServer.Load("GlobalHistoryWhatAreWeChangingDemoScenariosTo", Items.ReplacementText.ChoiceList);
	
	CheckRelevanceOfSearch(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchTextOnChange(Item)
	
	CheckRelevanceOfSearch(ThisObject);
	
EndProcedure

&AtClient
Procedure ReplacementTextOnChange(Item)
	
	CheckRelevanceOfSearch(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchForWholeWordOnChange(Item)
	
	CheckRelevanceOfSearch(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchTextAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ReplacementTextAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersResults

&AtClient
Procedure ResultsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Results.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "ResultsScenario" Then
		
		If ValueIsFilled(CurrentData.Scenario) Then
			
			SearchParameters = SearchParameters();
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("Key",            CurrentData.Scenario);
			OpeningParameters.Insert("ExecuteSearch",  True); 
			OpeningParameters.Insert("SearchParameters", SearchParameters);
			OpeningParameters.Insert("ScriptLanguage",    LanguageCodeOfFoundScript(CurrentData));
			
			OpenForm("Catalog.DemoScenarios.ObjectForm", OpeningParameters,
			             ThisObject,,,,,FormWindowOpeningMode.Independent);;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteSearch(Command)
	
	SearchParameters = SearchParameters();
	
	SearchTextFound        = SearchText;
	CaseSensitiveFound   = CaseSensitive;
	SearchForEntireWordFound = SearchForWholeWord;
	
	PerformSearchBySettings(SearchParameters);
	
EndProcedure

&AtClient
Procedure SelectCheckBoxes(Command)
	
	ChangeReplaceValue(True);
	
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	ChangeReplaceValue(False);
	
EndProcedure

&AtClient
Procedure Replace(Command)
	
	ClearMessages();
	
	ReplacementParameters = ReplacementParameters();
	
	If ReplacementParameters.BudgetingScenarios.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn kịch bản nào để thực hiện thay thế';
							|ru = 'Не выбран ни один сценарий для выполнения замены';
							|en = 'No scenario is selected for replacement'; fa = 'No scenario is selected for replacement';
							|it = 'Не выбран ни один сценарий для выполнения замены';
							|pl = 'No scenario is selected for replacement';
							|tr = 'Değişimi gerçekleştirmek için herhangi bir komut dosyası seçilmedi'");
		CommonClient.MessageToUser(MessageText, , "Results");
		Return;
	EndIf; 
	
	PerformReplacementAccordingToSettings(ReplacementParameters);
	
EndProcedure

#EndRegion 

#Region Private

&AtClient
Procedure ChangeReplaceValue(NewValue)

	For Each TableRow In Results Do
		TableRow.Replace = NewValue;
	EndDo;
	
EndProcedure 

&AtClient
Function LanguageCodeOfFoundScript(CurrentData)
	
	If CurrentData.FilesData.Count() > 0 Then
		Return CurrentData.FilesData[0].Value.LanguageCode;
	EndIf;
	
EndFunction

&AtServer
Procedure InitializeTheForm()
	
	StatePresentation = Items.SpreadsheetDocument.StatePresentation;
	
	StatePresentation.Visible                      = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture                       = New Picture;
	StatePresentation.Text                          = NStr("vi = 'Kết quả tìm kiếm không liên quan. Thực hiện tìm kiếm';
															|ru = 'Результаты поиска не актуальны. Выполните поиск';
															|en = 'The search results are obsolete. Search again'; fa = 'The search results are obsolete. Search again';
															|it = 'Результаты поиска не актуальны. Выполните поиск';
															|pl = 'The search results are obsolete. Search again';
															|tr = 'Arama sonuçları alakalı değil. Arama yapın'");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	If Form.SearchResultsAreUpToDate Then
		Form.Items.PagesFoundRelevant.CurrentPage = Form.Items.PageFound;
	Else
		Form.Items.PagesFoundRelevant.CurrentPage = Form.Items.PageIsNotRelevant;
	EndIf;
	
	ThereAreCurrentSearchResults = Form.SearchResultsAreUpToDate 
	                                 And Form.Results.Count() > 0;
	
	Form.Items.Replace.Enabled          = ThereAreCurrentSearchResults;
	Form.Items.SelectCheckBoxes.Enabled = ThereAreCurrentSearchResults;
	Form.Items.ClearCheckBoxes.Enabled      = ThereAreCurrentSearchResults;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure CheckRelevanceOfSearch(Form)

	SearchIsRelevant = True;
	
	If Form.SearchTextFound <> Form.SearchText Then
		SearchIsRelevant = False;
	EndIf;
	
	If Form.CaseSensitiveFound <> Form.CaseSensitive Then
		SearchIsRelevant = False;
	EndIf;
	
	If Form.SearchForEntireWordFound <> Form.SearchForWholeWord Then
		SearchIsRelevant = False;
	EndIf;
	
	Form.SearchResultsAreUpToDate = SearchIsRelevant;
	AvailabilityControl(Form);
	
EndProcedure

&AtClient
Function ReplacementParameters()
	
	ReplacementParameters = SearchParameters();
	ReplacementParameters.Insert("UUID", UUID);
	ReplacementParameters.Insert("BudgetingScenarios",                ScenariosInWhichReplacementIsPerformed());
	
	Return ReplacementParameters;
	
EndFunction

&AtClient
Function ScenariosInWhichReplacementIsPerformed()
	
	BudgetingScenarios = New Array;
	
	For Each ResultRow In Results Do
		
		If ResultRow.Replace Then
			
			ScenarioData = New Structure;
			ScenarioData.Insert("Scenario",     ResultRow.Scenario);
			ScenarioData.Insert("FilesData", ResultRow.FilesData);
			
			BudgetingScenarios.Add(ScenarioData);
			
		EndIf;
		
	EndDo;
	
	Return BudgetingScenarios;
	
EndFunction

#Region Replacement

&AtClient
Procedure PerformReplacementAccordingToSettings(ReplacementSettings)
	
	TimeConsumingOperation = PerformReplacementAccordingToSettingsLongOperation(ReplacementSettings,
	                                                                  UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		ReplacementBySettingsEnd(TimeConsumingOperation, Undefined);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		CallbackOnCompletion = New CallbackDescription("ReplacementBySettingsEnd", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Function PerformReplacementAccordingToSettingsLongOperation(ReplacementSettings, Var_UUID)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thay thế toàn cục trong các kịch bản minh họa';
														|ru = 'Глобальная замена в демонстрационных сценариях';
														|en = 'Global replacement in demo scenarios'; fa = 'Global replacement in demo scenarios';
														|it = 'Глобальная замена в демонстрационных сценариях';
														|pl = 'Global replacement in demo scenarios';
														|tr = 'Demo senaryolarında genel değişim'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DemoScenarios.PerformReplacementInDemoScenarios",
	                                                       ReplacementSettings, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction 

&AtClient
Procedure ReplacementBySettingsEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then 
		ProcessEndOfReplacementBySettings(Result.ResultAddress, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessEndOfReplacementBySettings(ResultAddress, AdditionalParameters)
	
	If IsTempStorageURL(ResultAddress) Then
		ReplacementResult = GetFromTempStorage(ResultAddress)
	EndIf;
	
	If ReplacementResult = Undefined Then
		Return;
	EndIf;
	
	If Not ReplacementResult.Success Then
		
		CommonClient.MessageToUser(ReplacementResult.UserMessage);
		Return;
		
	Else
		
		NotifyUserAboutResultsOfReplacement(ReplacementResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyUserAboutResultsOfReplacement(ReplacementResult)

	For Each DataOfError In ReplacementResult.Errors Do
		
		CommonClient.MessageToUser(DataOfError.ErrorText, DataOfError.Scenario);
		
	EndDo;
	
	If ReplacementResult.Processed = 0 Then
		
		NotificationText1 = NStr("vi = 'Chưa thực hiện thay thế trong một kịch bản minh họa';
								|ru = 'Замена ни в одном демонстрационном сценарии не выполнена';
								|en = 'Replacement is not performed in any demo scenario'; fa = 'Replacement is not performed in any demo scenario';
								|it = 'Замена ни в одном демонстрационном сценарии не выполнена';
								|pl = 'Replacement is not performed in any demo scenario';
								|tr = 'Herhangi bir demo senaryosunda değişim yapılmadı'");
		
	Else
		
		SearchResultsAreUpToDate = False;
		SearchTextFound      = "";
		
		NotificationText1 = StrTemplate(NStr("vi = 'Đã thực hiện thay thế trong kịch bản minh họa - %1 trong số %2';
											|ru = 'Выполнена замена в демонстрационных сценариях - %1 из %2';
											|en = 'Replacement is performed in the demo scenarios: %1 out of %2'; fa = 'Replacement is performed in the demo scenarios: %1 out of %2';
											|it = 'Выполнена замена в демонстрационных сценариях - %1 из %2';
											|pl = 'Replacement is performed in the demo scenarios: %1 out of %2';
											|tr = 'Demo senaryolarında değişim işlemi tamamlandı; %2 üzerindeki %1'"), 
		                            ReplacementResult.Processed, 
		                            ReplacementResult.ToProcessing);
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Thay thế trong các kịch bản';
								|ru = 'Замена в сценариях';
								|en = 'Replace in scenarios'; fa = 'Replace in scenarios';
								|it = 'Замена в сценариях';
								|pl = 'Replace in scenarios';
								|tr = 'Senaryolarda değişim'") ,, NotificationText1, PictureLib.Information32);
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region Search

&AtClient
Procedure PerformSearchBySettings(SearchSettings1)
	
	SelectionListsClientServer.UpdateSelectionList(Items.SearchText.ChoiceList, SearchText, 1000);
	SelectionListsClientServer.UpdateSelectionList(Items.ReplacementText.ChoiceList, ReplacementText, 1000);
	
	SelectionListsClientServer.Save("StoryIsGlobalThatWeAreChangingDemoScenarios", Items.SearchText.ChoiceList);
	SelectionListsClientServer.Save("GlobalHistoryWhatAreWeChangingDemoScenariosTo", Items.ReplacementText.ChoiceList);  
	
	Results.Clear();
	
	TimeConsumingOperation = PerformSearchBySettingsLongOperation(SearchSettings1,
	                                                                  UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		SearchBySettingsCompletion(TimeConsumingOperation, Undefined);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		CallbackOnCompletion = New CallbackDescription("SearchBySettingsCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Function PerformSearchBySettingsLongOperation(SearchSettings1, Var_UUID)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thay thế toàn cục trong các kịch bản minh họa';
														|ru = 'Глобальный поиск в демонстрационных сценариях';
														|en = 'Global search in demo scenarios'; fa = 'Global search in demo scenarios';
														|it = 'Глобальный поиск в демонстрационных сценариях';
														|pl = 'Global search in demo scenarios';
														|tr = 'Demo senaryolarında genel arama'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DemoScenarios.PerformSearchInDemoScripts",
	                                                       SearchSettings1, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure SearchBySettingsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then 
		ProcessEndOfSettingsSearch(Result.ResultAddress, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessEndOfSettingsSearch(ResultAddress, AdditionalParameters)
	
	If IsTempStorageURL(ResultAddress) Then
		SearchResult = GetFromTempStorage(ResultAddress)
	EndIf;
	
	If SearchResult = Undefined Then
		Return;
	EndIf;
	
	If Not SearchResult.Success Then
		
		CommonClient.MessageToUser(SearchResult.UserMessage);
		Return;
		
	Else
		
		UpdateSearchResultsTable(SearchResult.Results);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure UpdateSearchResultsTable(SearchResults)
	
	For Each ResultOfScenario In SearchResults Do
		
		NewRow = Results.Add();
		NewRow.Scenario            = ResultOfScenario.Scenario;
		NewRow.OccurrencesCount = ResultOfScenario.OccurrencesCount;
		NewRow.Replace            = True;
		NewRow.FilesData.LoadValues(ResultOfScenario.FilesData);
		
	EndDo;
	
	If Results.Count() = 0 Then
		
		NotificationText1 = NStr("vi = 'Chưa tìm thấy nội dung trong bất kỳ kịch bản nào';
								|ru = 'Текст не найден ни в одном из сценариев';
								|en = 'The text is not found in any scenario'; fa = 'The text is not found in any scenario';
								|it = 'Текст не найден ни в одном из сценариев';
								|pl = 'The text is not found in any scenario';
								|tr = 'Herhangi bir senaryoda metin bulunamadı'");
		
	Else
		
		NotificationText1 = StrTemplate(NStr("vi = 'Chưa tìm thấy nội dung trong các kịch bản minh họa - %1';
											|ru = 'Текст найден в демонстрационных сценариях - %1';
											|en = 'The text is found in the demo scenarios: %1'; fa = 'The text is found in the demo scenarios: %1';
											|it = 'Текст найден в демонстрационных сценариях - %1';
											|pl = 'The text is found in the demo scenarios: %1';
											|tr = 'Demo senaryolarında metin bulundu; %1'"), 
		                            Results.Count());
		
	EndIf; 
	
	ShowUserNotification(NStr("vi = 'Tìm kiếm trong các kịch bản';
								|ru = 'Поиск в сценариях';
								|en = 'Search in scenarios'; fa = 'Search in scenarios';
								|it = 'Поиск в сценариях';
								|pl = 'Search in scenarios';
								|tr = 'Senaryolarda arama'") ,, NotificationText1, PictureLib.Information32);
	
	CheckRelevanceOfSearch(ThisObject);

EndProcedure 

&AtClient
Function SearchParameters()

	SearchParameters = New Structure;
	
	SearchParameters.Insert("WhatWeAreChanging",              SearchText);
	SearchParameters.Insert("WhatAreWeChangingTo",            ReplacementText);
	SearchParameters.Insert("CaseSensitive",       CaseSensitive);
	SearchParameters.Insert("SearchForWholeWord",     SearchForWholeWord); 
	SearchParameters.Insert("HowToSearchInHyperlinks", ?(SearchInPartsOfLinks, "Any", "OnlyEntireLink"));
	
	Return SearchParameters;

EndFunction

#EndRegion

#EndRegion 


