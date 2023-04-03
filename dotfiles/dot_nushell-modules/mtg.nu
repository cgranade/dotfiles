export def "to-decklist" [] {
    select Count Name
        | each {|card| $"($card.Count)x ($card.Name)"}
        | str join "\n";
}
