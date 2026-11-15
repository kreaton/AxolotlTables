namespace AxolotlTables.Game;

/// <summary>One number on the floor: a tile in the 8 x 8 grid.</summary>
public sealed class Tile(int id, int value, bool inTable)
{
    public int Id { get; } = id;
    public int Value { get; } = value;

    /// <summary>Whether the number belongs in the table; the rest are fillers.</summary>
    public bool InTable { get; } = inTable;

    /// <summary>Picked up and put in its place in the table.</summary>
    public bool Placed { get; set; }
}

public sealed class TableGame
{
    public const int Columns = 5;
    public const int Rows = 5;

    private readonly Random _random = new();

    /// <summary>
    /// 1 or 2. Level 1 is the 2–5 tables up to 5 ×, level 2 the 2–10 tables up to 10 ×. The 1 table is left out:
    /// every number up to its end is in it, so there would be nothing else to put on the floor.
    /// </summary>
    public int Level { get; private set; } = 1;

    /// <summary>The highest table and the highest multiplier: 5 on level 1, 10 on level 2.</summary>
    public int Max => Level == 1 ? 5 : 10;

    /// <summary>The table being put back together, e.g. 3 for the 3 table.</summary>
    public int Number { get; private set; }

    /// <summary>How many numbers are in their place; the next one wanted is (Placed + 1) × Number.</summary>
    public int Placed { get; private set; }

    public int Mistakes { get; private set; }

    public IReadOnlyList<Tile> Tiles { get; private set; } = [];

    public bool IsWon => Placed == Max;

    public int NextValue => (Placed + 1) * Number;

    /// <summary>Starts a new table on the given level, never the same table twice in a row on a level.</summary>
    public void NewGame(int level)
    {
        var sameLevel = level == Level && Number != 0;
        Level = level;

        int number;
        do number = _random.Next(2, Max + 1);
        while (sameLevel && number == Number);

        Number = number;
        Placed = 0;
        Mistakes = 0;
        Tiles = MakeTiles();
    }

    /// <summary>
    /// The table's numbers, each exactly once, among fillers that are not in the table. The fillers are never
    /// bigger than the last number in the table, so a number can't be ruled out just for being too big.
    /// They are all different as long as there are enough of them (the 2 table on level 1 only has 1, 3, 5, 7 and 9).
    /// </summary>
    private List<Tile> MakeTiles()
    {
        var table = Enumerable.Range(1, Max).Select(k => k * Number).ToHashSet();
        var fillers = Enumerable.Range(1, Max * Number)
            .Where(v => !table.Contains(v))
            .OrderBy(_ => _random.Next())
            .ToArray();

        var values = table.Select(v => (Value: v, InTable: true)).ToList();
        for (var i = 0; values.Count < Columns * Rows; i++)
            values.Add((fillers[i % fillers.Length], false));

        return values
            .OrderBy(_ => _random.Next())
            .Select((v, i) => new Tile(i, v.Value, v.InTable))
            .ToList();
    }

    /// <summary>Tries to put the tile in the next place. Returns false, and counts a mistake, if it is the wrong number.</summary>
    public bool Pick(Tile tile)
    {
        if (IsWon || tile.Placed)
            return false;

        if (tile.Value != NextValue)
        {
            Mistakes++;
            return false;
        }

        tile.Placed = true;
        Placed++;
        return true;
    }
}
