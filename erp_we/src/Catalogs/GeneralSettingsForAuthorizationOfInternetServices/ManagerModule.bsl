///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns:
//  Structure:
//   * Ref - CatalogRef.GeneralSettingsForAuthorizationOfInternetServices
//   * InternetServiceName - String
//   * DataOwner - String
//   * AuthorizationAddress - String
//   * DeviceRegistrationAddress - String
//   * KeyReceiptAddress - String
//   * RedirectAddress - String
//   * PermissionsToRequest - String
//   * UsePKCEAuthenticationKey - Boolean
//   * AppID - String
//   * UseApplicationPassword - Boolean
//   * ApplicationPassword - String
//   * AdditionalAuthorizationParameters - String
//   * AdditionalTokenReceiptParameters - String
//   * ExplanationByRedirectAddress - String
//   * ExplanationByApplicationID - String
//   * ExplanationApplicationPassword - String
//   * AdditionalNote - String
//   * AliasRedirectAddresses - String
//   * ApplicationIDAlias - String
//   * ApplicationPasswordAlias - String
//   * RedirectAddressDefault - String
//   * RedirectionAddressWebClient - String
//
Function SettingsAuthorizationInternetService(InternetServiceName, DataOwner) Export
	
	AuthorizationSettings = New Structure;
	AuthorizationSettings.Insert("Ref");
	AuthorizationSettings.Insert("InternetServiceName");
	AuthorizationSettings.Insert("DataOwner");
	AuthorizationSettings.Insert("AuthorizationAddress");
	AuthorizationSettings.Insert("DeviceRegistrationAddress");
	AuthorizationSettings.Insert("KeyReceiptAddress");
	AuthorizationSettings.Insert("RedirectAddress");
	AuthorizationSettings.Insert("RedirectionAddressWebClient");
	AuthorizationSettings.Insert("PermissionsToRequest");
	AuthorizationSettings.Insert("UsePKCEAuthenticationKey");
	AuthorizationSettings.Insert("AppID");
	AuthorizationSettings.Insert("UseApplicationPassword");
	AuthorizationSettings.Insert("ApplicationPassword");
	AuthorizationSettings.Insert("AdditionalAuthorizationParameters");
	AuthorizationSettings.Insert("AdditionalTokenReceiptParameters");
	AuthorizationSettings.Insert("ExplanationByRedirectAddress", "");
	AuthorizationSettings.Insert("ExplanationByApplicationID", "");
	AuthorizationSettings.Insert("ExplanationApplicationPassword", "");
	AuthorizationSettings.Insert("AdditionalNote", "");
	AuthorizationSettings.Insert("AliasRedirectAddresses", "");
	AuthorizationSettings.Insert("ApplicationIDAlias", "");
	AuthorizationSettings.Insert("ApplicationPasswordAlias", "");
	AuthorizationSettings.Insert("RedirectAddressDefault", "");
	AuthorizationSettings.Insert("PasswordInputHint", "");
	
	QueryText =
	"SELECT
	|	GeneralSettingsForAuthorizationOfInternetServices.Ref AS Ref,
	|	GeneralSettingsForAuthorizationOfInternetServices.AuthorizationAddress AS AuthorizationAddress,
	|	GeneralSettingsForAuthorizationOfInternetServices.KeyReceiptAddress AS KeyReceiptAddress,
	|	GeneralSettingsForAuthorizationOfInternetServices.DeviceRegistrationAddress AS DeviceRegistrationAddress,
	|	GeneralSettingsForAuthorizationOfInternetServices.RedirectAddress AS RedirectAddress,
	|	GeneralSettingsForAuthorizationOfInternetServices.RedirectionAddressWebClient AS RedirectionAddressWebClient,
	|	GeneralSettingsForAuthorizationOfInternetServices.UsePKCEAuthenticationKey AS UsePKCEAuthenticationKey,
	|	GeneralSettingsForAuthorizationOfInternetServices.AppID AS AppID,
	|	GeneralSettingsForAuthorizationOfInternetServices.PermissionsToRequest AS PermissionsToRequest,
	|	GeneralSettingsForAuthorizationOfInternetServices.UseApplicationPassword AS UseApplicationPassword,
	|	GeneralSettingsForAuthorizationOfInternetServices.AdditionalAuthorizationParameters AS AdditionalAuthorizationParameters,
	|	GeneralSettingsForAuthorizationOfInternetServices.AdditionalTokenReceiptParameters AS AdditionalTokenReceiptParameters,
	|	GeneralSettingsForAuthorizationOfInternetServices.InternetServiceName AS InternetServiceName,
	|	GeneralSettingsForAuthorizationOfInternetServices.DataOwner AS DataOwner
	|FROM
	|	Catalog.GeneralSettingsForAuthorizationOfInternetServices AS GeneralSettingsForAuthorizationOfInternetServices
	|WHERE
	|	GeneralSettingsForAuthorizationOfInternetServices.DataOwner = &DataOwner
	|	AND GeneralSettingsForAuthorizationOfInternetServices.InternetServiceName = &InternetServiceName
	|	AND NOT GeneralSettingsForAuthorizationOfInternetServices.DeletionMark";
	
	Query = New Query(QueryText);
	Query.SetParameter("DataOwner", DataOwner);
	Query.SetParameter("InternetServiceName", InternetServiceName);
	
	SelectionDetailRecords = Query.Execute().Select();
	
	If SelectionDetailRecords.Next() Then
		
		FillPropertyValues(AuthorizationSettings, SelectionDetailRecords);
		
		AuthorizationSettings.ApplicationPassword = Common.ReadDataFromSecureStorage(
			SelectionDetailRecords.Ref, "ApplicationPassword");
		
	EndIf;
	
	Return AuthorizationSettings;
	
EndFunction

#EndRegion

#EndIf