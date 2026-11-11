///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var AdministrationParameters, PromptForIBAdministrationParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	NotifyOnClose = Parameters.NotifyOnClose;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	If Common.FileInfobase()
		Or Not ((Not SessionWithoutSeparators And Users.IsFullUser())
		Or Users.IsFullUser(, True)) Then
		
		Items.TerminateSession.Visible = False;
		Items.TerminateSessionContext.Visible = False;
		
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		Items.UsersListDataSeparation.Visible = False;
	EndIf;
	
	SortColumnName = "WorkStart";
	SortDirection = "Asc";
	
	FillConnectionFilterSelectionList();
	If Items.FilterApplicationName.ChoiceList.FindByValue(Parameters.FilterApplicationName) <> Undefined Then
		FilterApplicationName = Parameters.FilterApplicationName;
	EndIf;
	
	FillUserList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	PromptForIBAdministrationParameters = True;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	If NotifyOnClose Then
		NotifyOnClose = False;
		NotifyChoice(Undefined);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterApplicationNameOnChange(Item)
	FillList();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersList

&AtClient
Procedure UsersListSelection(Item, RowSelected, Field, StandardProcessing)
	OpenUserFromList();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TerminateSession(Command)
	
	SelectedLinesNumber = Items.UsersList.SelectedRows.Count();
	
	If SelectedLinesNumber = 0 Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn người sử dụng để kết thúc phiên làm việc.';
							|ru = 'Не выбраны пользователи для завершения сеансов.';
							|en = 'Please select users.'; fa = 'Please select users.';
							|it = 'Non sono selezionati utenti per terminare le sessioni di lavoro.';
							|pl = 'Brak użytkowników do ukończenia sesji.';
							|tr = 'Oturumları sonlandırmak için kullanıcılar seçilmez.'"));
		Return;
	ElsIf SelectedLinesNumber = 1 Then
		If Items.UsersList.CurrentData.Session = InfoBaseSessionNumber Then
			ShowMessageBox(,NStr("vi = 'Không thể kết thúc phiên làm việc hiện tại. Để thoát khỏi ứng dụng, có thể đóng cửa sổ chính của ứng dụng.';
								|ru = 'Невозможно завершить текущий сеанс. Для выхода из приложения можно закрыть главное окно приложения.';
								|en = 'Cannot close the current session. To exit the app, close its main window.'; fa = 'Cannot close the current session. To exit the app, close its main window.';
								|it = 'Невозможно завершить текущий сеанс. Для выхода из приложения можно закрыть главное окно приложения.';
								|pl = 'Cannot close the current session. To exit the app, close its main window.';
								|tr = 'Mevcut oturum kapatılamıyor. Uygulamadan çıkmak için ana pencereyi kapatın.'"));
			Return;
		EndIf;
	EndIf;
	
	SessionsNumbers = New Array;
	For Each RowID In Items.UsersList.SelectedRows Do
		SessionNumber = UsersList.FindByID(RowID).Session;
		If SessionNumber = InfoBaseSessionNumber Then
			Continue;
		EndIf;
		SessionsNumbers.Add(SessionNumber);
	EndDo;
	
	If CommonClient.DataSeparationEnabled()
	   And CommonClient.SeparatedDataUsageAvailable() Then
		
		StandardProcessing = True;
		NotificationAfterSessionTermination = New CallbackDescription(
			"AfterSessionTermination", ThisObject, New Structure("SessionsNumbers", SessionsNumbers));
		SSLSubsystemsIntegrationClient.OnEndSessions(ThisObject, SessionsNumbers, StandardProcessing, NotificationAfterSessionTermination);
		
	Else
		If PromptForIBAdministrationParameters Then
			CallbackDescription = New CallbackDescription("TerminateSessionContinued", ThisObject, SessionsNumbers);
			FormCaption = NStr("vi = 'Kết thúc phiên làm việc';
								|ru = 'Завершение сеанса';
								|en = 'Close session'; fa = 'بستن جلسه';
								|it = 'Chiudere la sessione';
								|pl = 'Zakończenie sesji';
								|tr = 'Oturumu sonlandırma'");
			NoteLabel = NStr("vi = 'Để kết thúc phiên làm việc,
				|hãy nhập các tham số quản trị cụm máy chủ';
				|ru = 'Для завершения сеанса введите параметры
				|администрирования кластера серверов';
				|en = 'To end the session, enter
				|the server cluster administration parameters'; fa = 'To end the session, enter
				|the server cluster administration parameters';
				|it = 'Per completare la sessione, inserire i parametri
				|di amministrazione del cluster di server';
				|pl = 'Aby zakończyć sesję, wprowadź parametry
				|administrowania klastera serwerów';
				|tr = 'Oturumu sonlandırmak için sunucu parametrelerinin 
				|yönetim ayarlarını girin'");
			IBConnectionsClient.ShowAdministrationParameters(CallbackDescription, False, True, AdministrationParameters, FormCaption, NoteLabel);
		Else
			TerminateSessionContinued(AdministrationParameters, SessionsNumbers);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshExecute()
	
	FillList();
	
EndProcedure

&AtClient
Procedure OpenEventLog()
	
	SelectedRows = Items.UsersList.SelectedRows;
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Hãy chọn người sử dụng để xem nhật ký sự kiện.';
							|ru = 'Выберите пользователей для просмотра журнала регистрации.';
							|en = 'Select users to view their event log records.'; fa = 'Select users to view their event log records.';
							|it = 'Scegliete gli utenti per la visualizzazione del registro.';
							|pl = 'Wybierz użytkowników, aby wyświetlić dziennik.';
							|tr = 'Olay günlüğünü görüntülemek için kullanıcıları seçin.'"));
		Return;
	EndIf;
	
	FilterForSpecifiedUsers = New ValueList;
	For Each RowID In SelectedRows Do
		UserRow1 = UsersList.FindByID(RowID);
		UserName = UserRow1.UserName;
		If FilterForSpecifiedUsers.FindByValue(UserName) = Undefined Then
			FilterForSpecifiedUsers.Add(UserRow1.UserName, UserRow1.UserName);
		EndIf;
	EndDo;
	
	OpenForm("DataProcessor.EventLog.Form", New Structure("User", FilterForSpecifiedUsers));
	
EndProcedure

&AtClient
Procedure SortAsc()
	
	SortByColumn("Asc");
	
EndProcedure

&AtClient
Procedure SortDesc()
	
	SortByColumn("Desc");
	
EndProcedure

&AtClient
Procedure OpenUser(Command)
	OpenUserFromList();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsersList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersList.Session");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	InfoBaseSessionNumber = InfoBaseSessionNumber();
	ItemFilter.RightValue = InfoBaseSessionNumber;

	Item.Appearance.SetParameterValue("Font", StyleFonts.MainListItem);

EndProcedure

&AtClient
Procedure FillList()
	
	// Saving the current session data that will be used to restore the row position.
	CurrentSession = Undefined;
	CurrentData = Items.UsersList.CurrentData;
	
	If CurrentData <> Undefined Then
		CurrentSession = CurrentData.Session;
	EndIf;
	
	FillUserList();
	
	// Restoring the current row position based on the saved session data.
	If CurrentSession <> Undefined Then
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Session", CurrentSession);
		FoundSessions = UsersList.FindRows(TheStructureOfTheSearch);
		If FoundSessions.Count() = 1 Then
			Items.UsersList.CurrentRow = FoundSessions[0].GetID();
			Items.UsersList.SelectedRows.Clear();
			Items.UsersList.SelectedRows.Add(Items.UsersList.CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SortByColumn(Direction)
	
	Column = Items.UsersList.CurrentItem;
	If Column = Undefined Then
		Return;
	EndIf;
	
	SortColumnName = Column.Name;
	SortDirection = Direction;
	
	FillList();
	
EndProcedure

&AtServer
Procedure FillConnectionFilterSelectionList()
	ApplicationNames = New Array;
	ApplicationNames.Add("1CV8");
	ApplicationNames.Add("1CV8C");
	ApplicationNames.Add("WebClient");
	ApplicationNames.Add("Designer");
	ApplicationNames.Add("COMConnection");
	ApplicationNames.Add("WSConnection");
	ApplicationNames.Add("BackgroundJob");
	ApplicationNames.Add("SystemBackgroundJob");
	ApplicationNames.Add("SrvrConsole");
	ApplicationNames.Add("COMConsole");
	ApplicationNames.Add("JobScheduler");
	ApplicationNames.Add("Debugger");
	ApplicationNames.Add("OpenIDProvider");
	ApplicationNames.Add("RAS");
	
	ChoiceList = Items.FilterApplicationName.ChoiceList;
	For Each ApplicationName In ApplicationNames Do
		ChoiceList.Add(ApplicationName, ApplicationPresentation(ApplicationName));
	EndDo;
EndProcedure

&AtServer
Procedure FillUserList()
	
	UsersList.Clear();
	
	If Not Common.DataSeparationEnabled()
	 Or Common.SeparatedDataUsageAvailable() Then
		
		Users.FindAmbiguousIBUsers(Undefined);
	EndIf;
	
	InfobaseSessions = GetInfoBaseSessions();
	ActiveUserCount = InfobaseSessions.Count();
	
	FilterApplicationNames = ValueIsFilled(FilterApplicationName);
	If FilterApplicationNames Then
		ApplicationNames = StrSplit(FilterApplicationName, ",");
	EndIf;
	
	UsersRefs = New Map;
	UsersIDs = New Array;
	For Each IBSession In InfobaseSessions Do
		If FilterApplicationNames
			And ApplicationNames.Find(IBSession.ApplicationName) = Undefined Then
			ActiveUserCount = ActiveUserCount - 1;
			Continue;
		EndIf;
		
		UserLine = UsersList.Add();
		
		UserLine.Application   = ApplicationPresentation(IBSession.ApplicationName);
		UserLine.WorkStart = IBSession.SessionStarted;
		UserLine.Computer    = IBSession.ComputerName;
		UserLine.Session        = IBSession.SessionNumber;
		UserLine.Join   = IBSession.ConnectionNumber;
		
		If TypeOf(IBSession.User) = Type("InfoBaseUser")
		   And ValueIsFilled(IBSession.User.Name) Then
			
			UserLine.User        = IBSession.User.Name;
			UserLine.UserName     = IBSession.User.Name;
			UsersIDs.Add(IBSession.User.UUID);
			UsersRefs[IBSession.User.UUID] = UserLine;
			
			If Common.DataSeparationEnabled() 
				And Users.IsFullUser(, True) Then
				
				UserLine.DataSeparation = DataSeparationValuesToString(
					IBSession.User.DataSeparation);
			EndIf;
			
		ElsIf Common.DataSeparationEnabled()
		        And Not Common.SeparatedDataUsageAvailable() Then
			
			UserLine.User       = Users.UnspecifiedUserFullName();
			UserLine.UserName    = "";
			UserLine.UserRef = Undefined;
		Else
			UnspecifiedProperties = UsersInternal.UnspecifiedUserProperties();
			UserLine.User       = UnspecifiedProperties.FullName;
			UserLine.UserName    = "";
			UserLine.UserRef = UnspecifiedProperties.Ref;
		EndIf;

		If IBSession.SessionNumber = InfoBaseSessionNumber Then
			UserLine.UserPictureNumber = 0;
		Else
			UserLine.UserPictureNumber = 1;
		EndIf;
		
	EndDo;

	PopulateRefsByIDs(UsersRefs, UsersIDs);
	UsersList.Sort(SortColumnName + " " + SortDirection);
	
EndProcedure

&AtServer
Function DataSeparationValuesToString(DataSeparation)
	
	Result = "";
	Value = "";
	If DataSeparation.Property("DataArea", Value) Then
		Result = String(Value);
	EndIf;
	
	HasOtherSeparators = False;
	For Each Separator In DataSeparation Do
		If Separator.Key = "DataArea" Then
			Continue;
		EndIf;
		If Not HasOtherSeparators Then
			If Not IsBlankString(Result) Then
				Result = Result + " ";
			EndIf;
			Result = Result + "(";
		EndIf;
		Result = Result + String(Separator.Value);
		HasOtherSeparators = True;
	EndDo;
	If HasOtherSeparators Then
		Result = Result + ")";
	EndIf;
	Return Result;
		
EndFunction

// Parameters:
//  UsersRefs - Map of KeyAndValue:
//    * Key - UUID
//    * Value - FormDataCollectionItem:
//      ** UserRef - CatalogRef.Users, CatalogRef.ExternalUsers
//  UsersIDs - Array of UUID
//
&AtServerNoContext
Procedure PopulateRefsByIDs(UsersRefs, UsersIDs)

	// Cannot access the separated catalog from a shared session.
	If Common.DataSeparationEnabled() 
		And Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If UsersIDs.Count() = 0 Then
		Return;
	EndIf;

	QueryTextTemplate2 = "SELECT
		|	Users.Ref AS Ref,
		|	Users.IBUserID AS IBUserID
		|FROM
		|	&TableName AS Users
		|WHERE
		|	Users.IBUserID IN (&IDs)";
					
	QueryTextForSpecifiedUsers = StrReplace(QueryTextTemplate2, "&TableName", 
		Metadata.Catalogs.Users.FullName());
	Query = New Query(QueryTextForSpecifiedUsers);
	Query.Parameters.Insert("IDs", UsersIDs);
	
	Selection = Query.Execute().Select();
	Count = 0;
	While Selection.Next() Do
		UsersRefs[Selection.IBUserID].UserRef = Selection.Ref;
		Count = Count + 1;
	EndDo;
	
	If Count < UsersIDs.Count() Then
		If ExternalUsers.UseExternalUsers() Then
			ExternalUserQueryText = StrReplace(QueryTextTemplate2, "&TableName", 
				Metadata.Catalogs.ExternalUsers.FullName());
			Query.Text = ExternalUserQueryText;
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				UsersRefs[Selection.IBUserID].UserRef = Selection.Ref;
			EndDo;
		EndIf;
		
		For Each UserRef In UsersRefs Do
			If Not ValueIsFilled(UserRef.Key) Then
				UserRef.Value.UserRef = Catalogs.Users.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenUserFromList()
	
	CurrentData = Items.UsersList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	User = CurrentData.UserRef;
	If ValueIsFilled(User) Then
		OpeningParameters = New Structure("Key", User);
		If TypeOf(User) = Type("CatalogRef.Users") Then
			OpenForm("Catalog.Users.ObjectForm", OpeningParameters);
		ElsIf TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			OpenForm("Catalog.ExternalUsers.ObjectForm", OpeningParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TerminateSessionContinued(Result, SessionsArray) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AdministrationParameters = Result;
	
	SessionStructure = New Structure;
	SessionStructure.Insert("Property", "Number");
	SessionStructure.Insert("ComparisonType", ComparisonType.InList);
	SessionStructure.Insert("Value", SessionsArray);
	Filter = CommonClientServer.ValueInArray(SessionStructure);
	
	Try
		DeleteInfobaseSessionsAtServer(AdministrationParameters, Filter)
	Except
		PromptForIBAdministrationParameters = True;
		Raise;
	EndTry;
	
	PromptForIBAdministrationParameters = False;
	
	AfterSessionTermination(DialogReturnCode.OK, New Structure("SessionsNumbers", SessionsArray));
	
EndProcedure

&AtClient
Procedure AfterSessionTermination(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		If AdditionalParameters.SessionsNumbers.Count() > 1 Then
			
			NotificationText1 = NStr("vi = 'Đã kết thúc phiên làm việc %1.';
									|ru = 'Сеансы %1 завершены.';
									|en = 'Sessions %1 are closed.'; fa = 'Sessions %1 are closed.';
									|it = 'Le sessioni %1 sono terminate.';
									|pl = 'Sesje %1 zakończone.';
									|tr = 'Oturumlar %1sona erdi.'");
			SessionsNumbers = StrConcat(AdditionalParameters.SessionsNumbers, ",");
			NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(NotificationText1, SessionsNumbers);
			ShowUserNotification(NStr("vi = 'Kết thúc phiên làm việc';
										|ru = 'Завершение сеансов';
										|en = 'Sessions closed'; fa = 'Sessions closed';
										|it = 'Chiudere le sessioni';
										|pl = 'Zakończenie sesji';
										|tr = 'Oturumları sonlandır'"),, NotificationText1);
			
		Else
			
			NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã hoàn tất phiên làm việc %1.';
					|ru = 'Сеанс %1 завершен.';
					|en = 'Session %1 is closed.'; fa = 'Session %1 is closed.';
					|it = 'La sessione %1 è terminata.';
					|pl = 'Sesja %1 zakończona.';
					|tr = 'Oturum %1sona erdi.'"), AdditionalParameters.SessionsNumbers[0]);
			ShowUserNotification(NStr("vi = 'Kết thúc phiên làm việc';
										|ru = 'Завершение сеанса';
										|en = 'Session closed'; fa = 'Session closed';
										|it = 'Chiudere la sessione';
										|pl = 'Zakończenie sesji';
										|tr = 'Oturumu sonlandırma'"),, NotificationText1);
			
		EndIf;
		
		FillList();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteInfobaseSessionsAtServer(AdministrationParameters, Filter)
	
	ClusterAdministration.DeleteInfobaseSessions(AdministrationParameters,, Filter);
	
EndProcedure

#EndRegion
