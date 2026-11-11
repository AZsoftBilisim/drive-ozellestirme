#Region Public

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Decomposes the magnetic card track data according to templates.
//
// Parameters:
//  TrackData - Array - array of strings. Values obtained from tracks.
//  TrackParameters - Array- an array of structures containing device configuration parameters, where:
//   * Use - Boolean - indicates whether the track is being used.
//   * TrackNumber - Number - the sequence number of track 1-3.
//
// Returns:
//  Array of Structure:
//   * Template - CatalogRef.MagneticStripeCardTemplates - ;
//   * TrackData - Structure:
//  	** Field - String
//  	** Simple - Arbitrary - 
//
Function DecryptMagneticCardCode(TrackData, TrackParameters) Export
	
	If TrackData.Count() = 0
		Or TrackParameters.Count() = 0 Then
		Return Undefined; // no data available
	EndIf;
	
	SelectionData = New Array;
	TrackCounter = 0;
	For Each CurParameter In TrackParameters Do
		If CurParameter.Use Then
			Try
				SelectionData.Add(New Structure("TrackNumber, TrackLength, TrackData_"
													, CurParameter.TrackNumber, StrLen(TrackData[TrackCounter]), TrackData[TrackCounter]));
			Except
				Return Undefined; // invalid template format
			EndTry;
		EndIf;
		TrackCounter = TrackCounter + 1;
	EndDo;
	
	// Stage 1. We are looking for patterns that match the length of the code
	// a) When comparing, only the available tracks play a role
	// b) It is necessary that at least one track is available.
	Query = New Query(
	"SELECT
	|	MagneticStripeCardTemplates.Ref,
	|	
	|	MagneticStripeCardTemplates.TrackAvailability1,
	|	MagneticStripeCardTemplates.Prefix1,
	|	MagneticStripeCardTemplates.Suffix1,
	|	MagneticStripeCardTemplates.CodeLength1,
	|	MagneticStripeCardTemplates.BlockSeparator1,
	|	
	|	MagneticStripeCardTemplates.TrackAvailability2,
	|	MagneticStripeCardTemplates.Prefix2,
	|	MagneticStripeCardTemplates.Suffix2,
	|	MagneticStripeCardTemplates.CodeLength2,
	|	MagneticStripeCardTemplates.BlockSeparator2,
	|	
	|	MagneticStripeCardTemplates.TrackAvailability3,
	|	MagneticStripeCardTemplates.Prefix3,
	|	MagneticStripeCardTemplates.Suffix3,
	|	MagneticStripeCardTemplates.CodeLength3,
	|	MagneticStripeCardTemplates.BlockSeparator3
	|FROM
	|	Catalog.MagneticStripeCardTemplates AS MagneticStripeCardTemplates
	|WHERE
	|	(MagneticStripeCardTemplates.TrackAvailability1
	|			OR MagneticStripeCardTemplates.TrackAvailability2
	|			OR MagneticStripeCardTemplates.TrackAvailability3)
	|	AND CASE
	|			WHEN MagneticStripeCardTemplates.TrackAvailability1
	|				THEN MagneticStripeCardTemplates.CodeLength1 = &CodeLength1
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN MagneticStripeCardTemplates.TrackAvailability2
	|				THEN MagneticStripeCardTemplates.CodeLength2 = &CodeLength2
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN MagneticStripeCardTemplates.TrackAvailability3
	|				THEN MagneticStripeCardTemplates.CodeLength3 = &CodeLength3
	|			ELSE TRUE
	|		END");
	Query.SetParameter("CodeLength1", StrLen(TrackData[0]));
	Query.SetParameter("CodeLength2", StrLen(TrackData[1]));
	Query.SetParameter("CodeLength3", StrLen(TrackData[2]));
	Selection = Query.Execute().Select();
	
	TemplateList = New Array;
	While Selection.Next() Do
		
		// 2nd stage - Skip the templates that do not match the suffix, prefix, separator.
		
		If Not CodeCorrespondsToMKPattern(TrackData, Selection) Then
			Continue;
		EndIf;
		
		TrackData_ = New Array;
		For Each CurrFilter In SelectionData Do
			For Each CurField In Selection.Ref["TrackFields"+String(CurrFilter.TrackNumber)] Do
				
				// Block search by number
				DataString_ = CurrFilter.TrackData_;
				Prefix = Selection["Prefix"+String(CurrFilter.TrackNumber)];
				If Prefix = Left(DataString_, StrLen(Prefix)) Then
					DataString_ = Right(DataString_, StrLen(DataString_)-StrLen(Prefix)); // We remove the prefix if there is
				EndIf;
				Suffix = Selection["Suffix"+String(CurrFilter.TrackNumber)];
				If Suffix = Right(DataString_, StrLen(Suffix)) Then
					DataString_ = Left(DataString_, StrLen(DataString_)-StrLen(Suffix)); // Remove the suffix if there is
				EndIf;
				
				CurBlockNumber = 0;
				While CurBlockNumber < CurField.BlockNumber Do
					BlockSeparator = Selection["BlockSeparator"+String(CurrFilter.TrackNumber)];
					SeparatorPosition = Find(DataString_, BlockSeparator);
					If IsBlankString(BlockSeparator) Or SeparatorPosition = 0 Then
						Block = DataString_;
					ElsIf SeparatorPosition = 1 Then
						Block = "";
						DataString_ = Right(DataString_, StrLen(DataString_)-1);
					Else
						Block = Left(DataString_, SeparatorPosition-1);
						DataString_ = Right(DataString_, StrLen(DataString_)-SeparatorPosition);
					EndIf;
					CurBlockNumber = CurBlockNumber + 1;
				EndDo;
				
				// Searching for a substring in a block
				Simple = Mid(Block, CurField.NumberOfFirstCharacter, ?(CurField.FieldLength = 0, StrLen(Block), CurField.FieldLength));
				
				FieldData = New Structure("Field, Simple", CurField.Field, Simple);
				TrackData_.Add(FieldData);
			EndDo;
		EndDo;
		Template = New Structure("Template, TrackData", Selection.Ref, TrackData_);
		TemplateList.Add(Template);
	EndDo;
	
	If TemplateList.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return TemplateList;
	
EndFunction

// Determines whether the card code matches the template.
// 
// Parameters:
//  TrackData - Array - An array containing lines of track code. There Are 3 Elements In Total.
//  TemplateData - Structure: 
//	 * Suffix - String
//	 * Prefix - String
//	 * BlockSeparator - String
//	 * CodeLength - Number
//
// Returns:
//  Boolean - True if the code matches the pattern.
//
Function CodeCorrespondsToMKPattern(TrackData, TemplateData) Export
	
	For Iterator_SSLy = 1 To 3 Do
		If TemplateData["TrackAvailability"+String(Iterator_SSLy)] Then
			CurRow = TrackData[Iterator_SSLy - 1];
			If Right(CurRow, StrLen(TemplateData["Suffix"+String(Iterator_SSLy)])) <> TemplateData["Suffix"+String(Iterator_SSLy)]
				Or Left(CurRow, StrLen(TemplateData["Prefix"+String(Iterator_SSLy)])) <> TemplateData["Prefix"+String(Iterator_SSLy)]
				Or Find(CurRow, TemplateData["BlockSeparator"+String(Iterator_SSLy)]) = 0
				Or StrLen(CurRow) <> TemplateData["CodeLength"+String(Iterator_SSLy)] Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	Return True;
	
EndFunction

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "Catalog.MagneticStripeCardTemplates";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndIf

#EndRegion