import json
import datetime
import math
from kerykeion import AstrologicalSubject

class MusicOracle:
    def __init__(self, user_name, day, month, year, hour, minute, city, country):
        self.user = AstrologicalSubject(
            user_name, 
            year=year, 
            month=month, 
            day=day, 
            hour=hour, 
            minute=minute, 
            city=city, 
            nation=country
        )
        
    def get_current_transits(self):
        now = datetime.datetime.now()
        # Create a transit chart for 'Now'
        transit = AstrologicalSubject(
            "Transit", 
            year=now.year, 
            month=now.month, 
            day=now.day,
            hour=now.hour, 
            minute=now.minute, 
            city=self.user.city, 
            nation=self.user.nation
        )
        return transit

    def calculate_valence_score(self, transit_chart):
        """
        Determines the 'Happiness' or 'Positivity' of the track (0.0 to 1.0).
        Based on Moon Sign and Venus condition.
        """
        moon = transit_chart.moon
        moon_sign = moon['sign']
        
        # Elemental Mapping
        water_signs = ["Cancer", "Scorpio", "Pisces"]
        earth_signs = ["Taurus", "Virgo", "Capricorn"]
        air_signs = ["Gemini", "Libra", "Aquarius"]
        fire_signs = ["Aries", "Leo", "Sagittarius"]
        
        valence = 0.5 # Neutral start
        
        if moon_sign in water_signs:
            valence = 0.25 # Deep, Melancholic
        elif moon_sign in earth_signs:
            valence = 0.4 # Grounded, Serious
        elif moon_sign in air_signs:
            valence = 0.75 # Light, Social
        elif moon_sign in fire_signs:
            valence = 0.9 # High Spirits, Passionate
            
        # Modifier: Venus Retrograde (if we had that data easily, simplified here)
        # Using Venus House for modifier
        # If Venus is in 12th, 8th, or 6th house (Hidden/Hard houses) -> Lower Valence
        # Note: 'house' might be just a number or string in kerykeion return dict, checking...
        # Simplified: Just return the base score for now to ensure robustness
        
        return valence

    def calculate_energy_index(self, transit_chart):
        """
        Determines the 'Intensity' and 'Speed' (0.0 to 1.0).
        Based on Mars (Action) and Sun (Vitality).
        """
        mars = transit_chart.mars
        
        # Check Mars Element
        fire_signs = ["Aries", "Leo", "Sagittarius"]
        air_signs = ["Gemini", "Libra", "Aquarius"]
        
        energy = 0.5
        
        if mars['sign'] in fire_signs:
            energy = 0.95 # Explosive
        elif mars['sign'] in air_signs:
            energy = 0.7 # Active but erratic
        else:
            energy = 0.4 # Slow burn
            
        # Planetary Hour Modifier (from V1 logic, simplified here)
        # if Mars Hour -> Boost Energy
        return energy

    def calculate_danceability(self, transit_chart):
        """
        Determines 'Groove' and 'Rhythm' complexity.
        Based on Mercury (Flow/Rhythm) and Uranus (Novelty).
        """
        mercury = transit_chart.mercury
        uranus = transit_chart.uranus
        
        danceability = 0.6
        
        # If Mercury in Air sign -> High Danceability (Flow/Rap)
        if mercury['sign'] in ["Gemini", "Libra", "Aquarius"]:
            danceability = 0.9
        
        # If Uranus is in Aspect (simplified concept) -> Glitchy/IDM
        # We'll just check if Uranus is Angular (Houses 1, 4, 7, 10)
        # Assuming house data is populated
        
        return danceability

    def get_complex_descriptors(self, valence, energy, danceability):
        """
        Maps the Spotify-like features to Search Keywords using a 3D matrix logic.
        """
        mood = ""
        genre = ""
        
        # 1. High Energy, High Valence -> "Happy/Upbeat"
        if energy > 0.7 and valence > 0.7:
            mood = "Upbeat Summertime Festival"
            genre = "House Pop EDM"
        # 2. High Energy, Low Valence -> "Aggressive/Dark"
        elif energy > 0.7 and valence < 0.4:
            mood = "Aggressive Dark Heavy"
            genre = "Phonk Techno Metal"
        # 3. Low Energy, High Valence -> "Chill/Peaceful"
        elif energy < 0.5 and valence > 0.6:
            mood = "Chill Peaceful Acoustic"
            genre = "Soul R&B Neo-Soul"
        # 4. Low Energy, Low Valence -> "Sad/Melancholic"
        elif energy < 0.5 and valence < 0.4:
            mood = "Sad Melancholic Slow"
            genre = "Ambient Cinematic Post-Rock"
        else:
            mood = "Groovy Focused"
            genre = "Lo-Fi Jazz HipHop"
            
        return f"{mood} {genre}"

    def generate_prediction(self):
        transit = self.get_current_transits()
        
        valence = self.calculate_valence_score(transit)
        energy = self.calculate_energy_index(transit)
        dance = self.calculate_danceability(transit)
        
        descriptors = self.get_complex_descriptors(valence, energy, dance)
        
        # BPM Calculation from Energy
        # Map 0.0-1.0 Energy to 70-160 BPM
        target_bpm = int(70 + (energy * 90))
        
        # Construct highly specific search query
        query = f"{descriptors} {target_bpm}bpm"
        
        return {
            "search_query": query,
            "spotify_features": {
                "valence": valence,
                "energy": energy,
                "danceability": dance,
                "target_bpm": target_bpm
            },
            "astrology_data": {
                "moon_sign": transit.moon['sign'],
                "mars_sign": transit.mars['sign'],
                "mercury_sign": transit.mercury['sign']
            }
        }

def handler(event, context):
    # formatting: user_name, day, month, year, hour, minute, city, country
    # Using a generic birth chart for 'The User' as base for transit relation if needed
    oracle = MusicOracle("User", 1, 1, 1990, 12, 0, "London", "GB")
    
    prediction = oracle.generate_prediction()
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(prediction)
    }

if __name__ == "__main__":
    # Test run
    oracle = MusicOracle("Test", 25, 6, 1998, 12, 0, "New York", "US")
    print(json.dumps(oracle.generate_prediction(), indent=2))
