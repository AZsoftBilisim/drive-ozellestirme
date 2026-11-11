#Region Public

Function ThereIsExchange() Export
	
	ErrorText = "";
	Return ApplicationParameters["StandardSubsystems.ObjectsOfTMCAERP.BackgroundJobIdentifier"] <> Undefined
		And Not ExchangeMobileOfflineServer.DataExchangeIsOver(ApplicationParameters["StandardSubsystems.ObjectsOfTMCAERP.BackgroundJobIdentifier"], ErrorText);
	
EndFunction

// The procedure performs data synchronization
// - asks the user for a password to access the main information security
// - system - starts the background synchronization process
// - if the background task could not be started, receives the error text and informs the user.
Procedure StartExchange() Export
	
#If MobileClient Then
		
		If Not ThereIsExchange() Then
			
			If MainServerAvailable() = True Then
				
				ApplicationParameters.Insert("StandardSubsystems.ObjectsOfTMCAERP.BackgroundJobIdentifier", ExchangeMobileOfflineServer.PerformDataExchangeInBackground());
				Notify("ExchangeBegan");
				AttachIdleHandler("MonitoringSynchronization", 2);
				
			Else
				
				Message = New UserMessage();
				Message.Text = NStr("vi = 'Không thể trao đổi. Máy chủ chính không hợp lệ';
									|ru = 'Обмен невозможен. Недоступен основной сервер.';
									|en = 'Exchange is not possible. The main server is unavailable.'; fa = 'Exchange is not possible. The main server is unavailable.';
									|it = 'Scambio impossibile. Non è disponibile il server principale.';
									|pl = 'Wymiana jest nie możliwa. Podstawowy serwer jest niedostępny.';
									|tr = 'Değişim mümkün değildir. Ana sunucu kullanılamıyor.'", "ru");
				Message.Message();
				
			EndIf;
			
		EndIf;
		
#EndIf
	
EndProcedure

Procedure DisableWaitHandlers() Export
	
	DetachIdleHandler("SessionTerminationModeManagement");
	DetachIdleHandler("WarnAbout1CReportingProblems");
	DetachIdleHandler("WarnAboutEDOPFRStatements");
	DetachIdleHandler("WarnAboutIncorrectStatusesOfSending2NDFL");
	DetachIdleHandler("WarnAboutAstralM");
	DetachIdleHandler("SendingBuhReportsToVPARK");
	DetachIdleHandler("ShowSPARKWarning");
	DetachIdleHandler("ProcessChangedFSGSCodes");
	DetachIdleHandler("GetInformationAboutIncomingMessagesForEDIUser");
	DetachIdleHandler("WarnAboutConflictOfCryptoproviders");
	
EndProcedure

// The procedure starts the background process of creating a Mobile exchange plan node for offline configuration
Procedure CreateExchangeNode() Export
	
	ApplicationParameters.Insert("StandardSubsystems.ObjectsOfTMCAERP.BackgroundJobIdentifier", ExchangeMobileOfflineServer.CreateExchangeNodeInBackground());
	
EndProcedure

// The function gets the node of the exchange plan Mobile offline configuration for the current session
// Returns:
//  String - Exchange Plan Node code
//
Function CurrentNode() Export
	
	Return ExchangeMobileOfflineServer.CurrentNode();
	
EndFunction

#EndRegion