
#Region Internal


// Returns the data types used for the item being defined, taking into account the functional options.
// A type is removed from the type array if there is at least 1 FO that includes the type and there is no active FO.
// 
// Returns:
//  Array of Type
//
Function TypesOfBADNomenclatureUsed() Export
	
	TypesUsed = Metadata.DefinedTypes.EDLProducts.Type.Types();
	TotalTypes       = TypesUsed.Count();
	
	If TotalTypes > 1 Then
		For ReverseIndex = 1 To TotalTypes Do
			Current_Type     = TypesUsed[TotalTypes - ReverseIndex];
			TypeMetadata = Metadata.FindByType(Current_Type);
			ThereIsFO         = False;
			ThereIsActiveFO = False;
			For Each FunctionalOption In Metadata.FunctionalOptions Do
				If FunctionalOption.Content.Find(TypeMetadata) <> Undefined Then
					ThereIsFO         = True;
					ThereIsActiveFO = (GetFunctionalOption(FunctionalOption.Name) = True);
					If ThereIsActiveFO Then
						Break;
					EndIf;
				EndIf;
			EndDo;
			If ThereIsFO And Not ThereIsActiveFO Then
				TypesUsed.Delete(TotalTypes - ReverseIndex);
			EndIf;
		EndDo;
	EndIf;
	
	Return TypesUsed;
	
EndFunction

#EndRegion

#Region Private


#EndRegion
