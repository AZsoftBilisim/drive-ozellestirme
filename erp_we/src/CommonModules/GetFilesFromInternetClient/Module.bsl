///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens a proxy server parameters form.
//
// Parameters:
//    FormParameters - Structure - parameters of the form to be opened.
//
Procedure OpenProxyServerParametersForm(FormParameters = Undefined) Export
	
	OpenForm("CommonForm.ProxyServerParameters", FormParameters);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Gets the file from the Internet via http(s) protocol or ftp protocol and saves it at the specified path on client.
// Unavailable in web client. If you work in web client, use similar
// server procedures for downloading files.
//
// Parameters:
//   URL                - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters.
//   WriteError1   - Boolean - if True, write file download errors to the event log.
//
// Returns:
//   Structure - information on a received file:
//      * Status            - Boolean - True if a file is successfully received.
//      * Path              - String - path to the file on the client. This key is used only if Status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode      - Number - Added in case of an error.
//                                    See the "StatusCode" parameter of the "HTTPResponse" object in Syntax Assistant.
//
Function DownloadFileAtClient(Val URL, Val ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
#If WebClient Then
	Raise NStr("vi = 'Không cho phép tải tệp xuống Client khi làm việc trong Web-client.';
				|ru = 'Скачивание файлов на клиент недоступно при работе в веб-клиенте.';
				|en = 'Cannot download files in the web client.'; fa = 'Cannot download files in the web client.';
				|it = 'Il download di file sul client non è disponibile quando si lavora nel client Web.';
				|pl = 'Pobieranie plików do klienta nie jest dostępne podczas pracy w kliencie Web.';
				|tr = 'Web istemcisinde çalışırken dosyalar istemciye indirilemez.'");
#Else
	
	Result = GetFilesFromInternetInternalServerCall.DownloadFile(URL, ReceivingParameters, WriteError1);
	
	If ReceivingParameters <> Undefined
		And ReceivingParameters.PathForSaving <> Undefined Then
		
		PathForSaving = ReceivingParameters.PathForSaving;
	Else
		PathForSaving = GetTempFileName(); // ACC:441 The temporary file must be deleted by the calling code.
	EndIf;
	
	If Result.Status Then
		// ACC:1348-off FileSystemClient.SaveFiles is not used for compatibility (synchronous call).
		GetFile(Result.Path, PathForSaving, False); 
		// ACC:1348-on
		Result.Path = PathForSaving;
	EndIf;
	
	Return Result;
	
#EndIf
	
EndFunction

#EndRegion

#EndRegion
